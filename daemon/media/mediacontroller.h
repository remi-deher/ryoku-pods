#ifndef MEDIACONTROLLER_H
#define MEDIACONTROLLER_H

#include <QObject>
#include "pulseaudiocontroller.h"

class QProcess;
class QTimer;
class EarDetection;
class PlayerStatusWatcher;
class QDBusInterface;

class MediaController : public QObject
{
  Q_OBJECT
public:
  enum MediaState
  {
    Playing,
    Paused,
    Stopped
  };
  Q_ENUM(MediaState)
  enum EarDetectionBehavior
  {
    PauseWhenOneRemoved,
    PauseWhenBothRemoved,
    Disabled
  };
  Q_ENUM(EarDetectionBehavior)

  explicit MediaController(QObject *parent = nullptr);
  ~MediaController();

  void handleEarDetection(EarDetection*);
  void followMediaChanges();
  bool isActiveOutputDeviceAirPods();
  void handleConversationalAwareness(const QByteArray &data);
  void activateA2dpProfileWithRetry(const QString &macAddress);
  void cancelPendingA2dpActivation();
  void removeAudioOutputDevice();
  void setConnectedDeviceMacAddress(const QString &macAddress);
  bool isA2dpProfileAvailable();
  QString getPreferredA2dpProfile();
  QString getActiveProfile();
  bool restartWirePlumber();

  void setEarDetectionBehavior(EarDetectionBehavior behavior);
  inline EarDetectionBehavior getEarDetectionBehavior() const { return earDetectionBehavior; }

  void play();
  void pause();
  MediaState getCurrentMediaState() const;

Q_SIGNALS:
  void mediaStateChanged(MediaState state);

private:
  MediaState mediaStateFromPlayerctlOutput(const QString &output) const;
  QString getAudioDeviceName();
  QStringList getPlayingMediaPlayers();
  // Only the retry chain calls this, so the one-restart flag below cannot be read outside a chain.
  bool activateA2dpProfile();
  void attemptA2dpActivation(const QString &macAddress, quint64 generation, int attempt, int unanswered = 0);

  // Conversational awareness ducking: one session from the first voice until the volume is back.
  void caStartRamp(double to, double tauMs, bool restoreCurve = false);
  void caRampTick();
  void caHoldExpired();
  void caEndSession();

  QStringList pausedByAppServices;
  int initialVolume = -1;
  QTimer *m_caHoldTimer = nullptr;
  QTimer *m_caRampTimer = nullptr;
  QString m_caSink;
  QString m_caSnapSink;
  double m_caLevel = 0;
  double m_caRampFrom = 0;
  double m_caRampTo = 0;
  double m_caTauMs = 150;
  qint64 m_caRampStartMs = 0;
  int m_caLastSet = -1;
  bool m_caRestoreCurve = false;
  QString connectedDeviceMacAddress;
  EarDetectionBehavior earDetectionBehavior = PauseWhenOneRemoved;
  QString m_deviceOutputName;
  PlayerStatusWatcher *playerStatusWatcher = nullptr;
  PulseAudioController *m_pulseAudio = nullptr;
  QString m_cachedA2dpProfile;
  quint64 m_earDetectionGeneration = 0;
  bool m_earOutPending = false;
  // A queued retry compares its captured generation against this, so a superseded chain stops.
  quint64 m_a2dpRetryGeneration = 0;
  bool m_wirePlumberRestartedThisChain = false;
};

#endif // MEDIACONTROLLER_H
