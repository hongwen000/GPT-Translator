#include "controller.h"

using namespace std;

Setting::Setting(QObject * parent): QObject{parent}
{
    _apiServer = "";
    _apiKey = "";
    _model = "";
    _shortCut = "";
    //win C:\Users\xxxx\AppData\Local\GPT_Translator
    //macos /Users/xxx/Library/Preferences/GPT_Translator/
    _configPath = QStandardPaths::locate(QStandardPaths::AppConfigLocation, "config.json", QStandardPaths::LocateFile);
    if(_configPath == ""){
        if(QStandardPaths::standardLocations(QStandardPaths::AppConfigLocation).length() > 0){
            QString path = QStandardPaths::standardLocations(QStandardPaths::AppConfigLocation).at(0);
            QDir dir(path);
            if (!dir.exists()){
                dir.mkdir(path);
                qDebug() << "mkdir:" << path;
            }
            _configPath = path + "/config.json";

        }else{
            assert("no writeable location found");
            return;
        }
    }else{
        loadConfig();
    }

    QFile configFile(_configPath);
    qDebug() << QStandardPaths::displayName(QStandardPaths::AppConfigLocation);

    if(!configFile.exists()){
        updateConfig();
    }
}

bool Setting::loadConfig()
{
   QFile file(_configPath);
   string content = "";
   if(file.open(QIODevice::ReadOnly)){
       content = file.readAll().toStdString();
       file.close();
   }
   QJsonDocument doc = QJsonDocument::fromJson(QString::fromStdString(content).toUtf8());
    if (!doc.isNull()) {
        if (doc.isObject()) {
            QJsonObject obj = doc.object();
            _apiKey = obj.value("apiKey").toString();
            _model = obj.value("model").toString();
            _apiServer = obj.value("apiServer").toString();
            _shortCut = obj.value("shortCut").toString();
            if(_apiServer.trimmed().length() == 0){
                _apiServer = "http://ipads.chat.gpt:3006";
            }
            return true;
        }
    }
    return false;
}

void Setting::updateConfig()
{
    QString s = "{\"apiKey\":\"" + _apiKey + "\",\"model\":\"" + _model + "\", \"apiServer\":\"" + _apiServer + "\", \"shortCut\":\"" + _shortCut + "\"}";
    QFile file(_configPath);
    if(file.open(QIODevice::WriteOnly)){
        QTextStream out(&file);
        out << s;
        file.close();
    }
}


Controller::Controller(QObject *parent)
    : QObject{parent}
{
    _responseData = "";
    _responseError = "";
    _transToLang = "";
    _isRequesting = false;
    _apiServer = "";
    _apiKey = "";
    _model = "";
    networkManager = new QNetworkAccessManager(this);

}

QJsonObject Controller::createMessage(const QString& role,const QString& content){
    QJsonObject message;
    message.insert("role",role);
    message.insert("content",content);
    return message;
}


std::tuple<QString, bool> Controller::_getContent(QString &str)
{
    QJsonDocument doc = QJsonDocument::fromJson(str.toUtf8());
    if (!doc.isNull()) {
        if (doc.isObject()) {
            QJsonObject obj = doc.object();
             QString text = "";
            if(obj.contains("error")){
                text = obj.value("error").toObject().value("message").toString();
                return std::make_tuple(text, false);
            }else{
                text = obj.value("choices").toArray().at(0).toObject().value("delta").toObject().value("content").toString();
                return std::make_tuple(text, true);
            }
        }
    }
    return std::make_tuple("", false);
}

std::tuple<QString, bool> Controller::_parseResponse(QByteArray &ba)
{
    QString data;
    bool error = false;
    QStringList lines = QString::fromUtf8(ba).split("data:");
    for (const QString &line : lines) {
        QString eventData = line.trimmed();;
//        qDebug() <<eventData;
        QString text;
        bool haveError;
        std::tie(text, haveError) = _getContent(eventData);
        data += text;
        error |= haveError;
    }
    return std::make_tuple(data, error);

}


void Controller::streamReceived()
{

    QByteArray response = reply->readAll();
    QString text;
    bool haveError;
    std::tie(text, haveError) = _parseResponse(response);
    _data += text;
    responseData(_data);

}


void Controller::sendMessage(QString str, int mode)
{
    if(_apiServer.trimmed().length() == 0){
        _apiServer = "http://ipads.chat.gpt:3006";
    }

    if(_apiKey.length() < 10){
        responseError("Please provide the correct apikey");
        return;
    }
    QUrl apiUrl(_apiServer + "/v1/chat/completions");
      QNetworkRequest request(apiUrl);
      request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
      request.setRawHeader("Authorization", QString::fromStdString("Bearer %1").arg(_apiKey.trimmed()).toUtf8());
      request.setAttribute(QNetworkRequest::CacheLoadControlAttribute, QNetworkRequest::AlwaysNetwork); // Events shouldn't be cached

      QJsonObject requestData;
      QJsonArray messages;
      requestData.insert("model", _model);
      requestData.insert("stream", true);
//      qDebug() << _transToLang;
      QString systemcmd;
      if(mode == 0){
        systemcmd = QString::fromStdString("Translate the text to %1, which is delimited with triple backticks. Only return the translate result, don’t interpret it, don't return the delimited character.").arg(_transToLang);
        messages.append(createMessage("system",systemcmd));
        messages.append(createMessage("user", "translate text:'''" + str + "'''" ));
      }else if(mode == 1){
          systemcmd = QString::fromStdString("Translate anything that I say to %1. When the text contains only one single word, please provide the original form (if applicable), \
  the language of the word, the corresponding phonetic transcription (if applicable), \
  all meanings (including parts of speech), and at least three bilingual examples. Please strictly follow the format below:\
                                             <Original Text> \n \
                                             [<Language>] · / <Phonetic Transcription> \n \
                                             [<Part of Speech Abbreviation>] <Chinese Meaning>] \n \
                                             Examples: \n\
                                             <Number><Example>(Example Translation).The content in this format must be %1 either").arg(_transToLang);
          messages.append(createMessage("system",systemcmd));
          messages.append(createMessage("user","\"" + str + "\""));
      }else{
        QString systemcmd = QString::fromStdString(
            "Role and Goal: This GPT acts as an English translator, spelling corrector, and language improver. "
            "It translates English and Chinese text into academically-improved English with spelling corrections, "
            "without providing explanations. The GPT follows two input modes: 1) Standard input without curly brackets, "
            "where it translates and improves the text. 2) Input enclosed in curly brackets, which is user feedback on "
            "translations, requiring adjustments as per user instructions. \n\n"
            "Constraints: The GPT should not offer explanations for its translations or improvements, focusing solely on "
            "delivering the refined text. \n\n"
            "Guidelines: Emphasize accuracy in translation, academic tone, and spelling correctness. Adjust translations "
            "based on user feedback in curly brackets. \n\n"
            "Clarification: Avoid asking for clarifications. Instead, make informed assumptions to fulfill the user's request "
            "for translation and improvement. \n\n"
            "Personalization: Maintain a formal and academic style, focusing on language precision and enhancement."
            );

        messages.append(createMessage("system", systemcmd));
        messages.append(createMessage("user", "The sentence is: [" + str + "]"));
    }



      requestData.insert("messages", messages);
      QJsonDocument requestDoc(requestData);
      QByteArray requestDataBytes = requestDoc.toJson();
//      qDebug() << requestDataBytes;

      _data = "";
      responseData(_data);
      isRequesting(true);
      reply = networkManager->post(request, requestDataBytes);
      connect(reply, SIGNAL(readyRead()), this, SLOT(streamReceived()));


      connect(reply, &QNetworkReply::finished,this, [=]() {
          isRequesting(false);
          qDebug() << "finished";
          QByteArray response = reply->readAll();
          QString text;
          bool haveError;
          std::tie(text, haveError) = _parseResponse(response);
          _data += text;
          responseData(_data);
          if (reply->error() == QNetworkReply::NoError) {
              responseError("");
          } else {
              if(reply->error() > 0 && reply->error() < 100){
                  if(reply->error() != QNetworkReply::OperationCanceledError){
                     responseError("network error");
                  }

              }else if(reply->error() > 100 && reply->error() < 200){
                  responseError("proxy error");
              }else if(reply->error() > 200 && reply->error() < 300){
                  responseError("content error");
              }else if(reply->error() > 300 && reply->error() < 400){
                  responseError("protocol error");
              }else if(reply->error() > 400 && reply->error() < 500){
                  responseError("server error");
              }
              qDebug() << reply->error() ;
              qDebug() << "网络错误："+  reply->errorString();
          }
          reply->deleteLater();
          reply = nullptr;
      });
}


void Controller::abort()
{
    try {
        if(reply)
        reply->abort();
    } catch (...) {
    }
}



