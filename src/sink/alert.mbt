// MoonBit Stream Quality Engine - Alert Trigger Module
// Copyright 2026 zmjknn
// Apache-2.0 License

/// Alert Level.
pub(all) enum AlertLevel {
  AlertWarning
  AlertError
  AlertCritical
} derive(Eq, Debug)

/// Alert Trigger Payload for downstream notification systems (Webhook, Slack, Log, AlertManager).
pub(all) struct AlertPayload {
  alert_id : String
  pipeline_name : String
  level : AlertLevel
  title : String
  description : String
  quality_score : Double
  timestamp : Int64
} derive(Eq, Debug)

/// Creates a new AlertPayload.
pub fn AlertPayload::new(
  alert_id : String,
  pipeline_name : String,
  level : AlertLevel,
  title : String,
  description : String,
  quality_score : Double,
  timestamp : Int64
) -> AlertPayload {
  {
    alert_id,
    pipeline_name,
    level,
    title,
    description,
    quality_score,
    timestamp,
  }
}

/// Alert Rule Threshold evaluator checking if quality score drops below min score.
pub(all) struct AlertConfig {
  min_acceptable_score : Double
  critical_score_threshold : Double
  webhook_url : String
} derive(Eq, Debug)

/// Creates default AlertConfig.
pub fn AlertConfig::default() -> AlertConfig {
  {
    min_acceptable_score: 85.0,
    critical_score_threshold: 60.0,
    webhook_url: "https://alert.example.com/webhook",
  }
}

/// Evaluates quality score against alert thresholds and returns optional AlertPayload.
pub fn AlertConfig::check_alert(
  self : AlertConfig,
  pipeline_name : String,
  quality_score : Double,
  timestamp : Int64
) -> AlertPayload? {
  if quality_score < self.critical_score_threshold {
    Some(
      AlertPayload::new(
        "alt-crit-" + timestamp.to_string(),
        pipeline_name,
        AlertCritical,
        "CRITICAL: Data Stream Quality Score Dropped Severely",
        "Stream quality score " + quality_score.to_string() + " is below critical threshold " + self.critical_score_threshold.to_string(),
        quality_score,
        timestamp,
      )
    )
  } else if quality_score < self.min_acceptable_score {
    Some(
      AlertPayload::new(
        "alt-warn-" + timestamp.to_string(),
        pipeline_name,
        AlertWarning,
        "WARNING: Data Stream Quality Score Below Target",
        "Stream quality score " + quality_score.to_string() + " is below target threshold " + self.min_acceptable_score.to_string(),
        quality_score,
        timestamp,
      )
    )
  } else {
    None
  }
}

/// Formats AlertPayload into JSON string for Webhook POST payload.
pub fn AlertPayload::to_webhook_json(self : AlertPayload) -> String {
  let level_str = match self.level {
    AlertWarning => "WARNING"
    AlertError => "ERROR"
    AlertCritical => "CRITICAL"
  }
  "{\"alert_id\":\"" + self.alert_id + "\",\"pipeline\":\"" + self.pipeline_name + "\",\"level\":\"" + level_str + "\",\"title\":\"" + self.title + "\",\"score\":" + self.quality_score.to_string() + ",\"timestamp\":" + self.timestamp.to_string() + "}"
}
