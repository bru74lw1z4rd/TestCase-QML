#ifndef FILEREADER_H
#define FILEREADER_H

#include <QFile>
#include <QFileInfo>
#include <QFuture>
#include <QMutex>
#include <QMutexLocker>
#include <QObject>
#include <QRegularExpression>
#include <QTextStream>
#include <QThreadPool>
#include <QUrl>
#include <QtConcurrent>

class FileReader : public QObject {
    Q_OBJECT

    Q_PROPERTY(bool paused READ getPause WRITE setPause NOTIFY pauseChanged)
    Q_PROPERTY(quint64 currentProgress READ currentProgress NOTIFY currentProgressChanged)
    Q_PROPERTY(quint64 totalFileLength READ totalFileLength NOTIFY totalFileLengthChanged)

#define androidUri "content:"
#define maxThreadCount 1
#define minimumWordLength 2

#define initializeFileReaderErrors qmlRegisterUncreatableType<FileReader>("FileReader.FileReaderError", 1, 0, "FileReaderError", "Cannot initialize FileReaderError in QML");

public:
    explicit FileReader(QObject* parent = nullptr);
    ~FileReader()
    {
        m_canceled = true;
    }

    enum class FileReaderError {
        NoError = 0,
        OpenError = 1,
        ReadingError = 2
    };
    Q_ENUM(FileReaderError)

    /*********/
    /* pause */
    /*********/

    [[nodiscard]] inline bool getPause() const
    {
        return m_paused;
    }

    inline void setPause(const bool paused)
    {
        /* Блокируем mutex, чтобы избежать проблем с синхронизацией */
        QMutexLocker locker(&m_workThreadMutex);

        m_paused = paused;

        /* Если пользователь продолжил исполнение */
        if (m_paused == false && m_canceled == false) {
            m_workThreadWaitCondition.wakeAll();
        }

        emit pauseChanged();
    }

    /*******************/
    /* currentProgress */
    /*******************/

    [[nodiscard]] inline quint64 currentProgress() const
    {
        return m_currentProgress;
    }

    inline void setCurrentProgress(const quint64 currentProgress)
    {
        m_currentProgress = currentProgress;
        emit currentProgressChanged();
    }

    /*******************/
    /* totalFileLength */
    /*******************/

    [[nodiscard]] inline quint64 totalFileLength() const
    {
        return m_totalFileLength;
    }

    inline void setTotalFileLength(const quint64 totalFileLength)
    {
        m_totalFileLength = totalFileLength;
        emit totalFileLengthChanged();
    }

public slots:
    ///
    /// \brief prepareFile - Функция подготавливает файл к дальнейшей обработке.
    /// \param filePath - Путь к файлу в системе.
    /// \return Возвращает 'true', если удалось подготовить файл для дальнейшего чтения и 'false' при ошибке.
    ///
    [[nodiscard]] bool prepareFile(QString filePath);

    ///
    /// \brief startWork - Функция запускает работу по считыванию слов в файле.
    ///
    void startWork();

    ///
    /// \brief cancel - Функция отменяет запланированную работу с файлом.
    ///
    inline void cancel()
    {
        m_canceled = true;
    }

    ///
    /// \brief pause - Функция ставит на паузу обработку файла. Функция создана для удобства
    ///
    inline void pause()
    {
        setPause(true);
    }

    ///
    /// \brief resume - Функция возобновляет обработку файла. Функция создана для удобства
    ///
    inline void resume()
    {
        setPause(false);
    }

signals:
    void workCanceledChanged();
    void newWordFoundChanged(const QString& word);
    void errorOccured(const FileReaderError error, const QString& reason);

    void pauseChanged();
    void currentProgressChanged();
    void totalFileLengthChanged();

private:
    /***/
    /***/
    /***/

    bool m_paused = false;
    bool m_canceled = false;
    quint64 m_currentProgress = 0;
    quint64 m_totalFileLength = 0;
    QString m_filePath;

    QMutex m_workThreadMutex;
    QWaitCondition m_workThreadWaitCondition;
    QThreadPool m_workThreadPool;

    const QStringList acceptableFileFormats { "txt" };
    const QRegularExpression m_wordRegularExpression;
};

Q_DECLARE_METATYPE(FileReader::FileReaderError)

#endif // FILEREADER_H
