class DiagnosticResult {
  final String status;
  final String? caseNumber;
  final String cropType;
  final bool isSupported;
  final String confidenceBand;
  final double confidenceScore;
  final String diagnosis;
  final String severity;
  final String? knowledgeDocId;
  final Map<String, dynamic> vettedAdvice;
  final String message;
  final String? imageUrl;
  final DateTime timestamp;

  DiagnosticResult({
    required this.status,
    this.caseNumber,
    required this.cropType,
    required this.isSupported,
    required this.confidenceBand,
    required this.confidenceScore,
    required this.diagnosis,
    required this.severity,
    this.knowledgeDocId,
    required this.vettedAdvice,
    required this.message,
    this.imageUrl,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory DiagnosticResult.fromJson(Map<String, dynamic> json, {String? localImage}) {
    return DiagnosticResult(
      status: json['status'] ?? 'UNKNOWN',
      caseNumber: json['case_number'],
      cropType: json['crop_type'] ?? 'Unknown',
      isSupported: json['is_supported'] ?? true,
      confidenceBand: json['confidence_band'] ?? 'MEDIUM',
      confidenceScore: (json['confidence_score'] ?? 0.0).toDouble(),
      diagnosis: json['diagnosis'] ?? 'Pending Evaluation',
      severity: json['severity'] ?? 'Moderate',
      knowledgeDocId: json['knowledge_doc_id'],
      vettedAdvice: Map<String, dynamic>.from(json['vetted_advice'] ?? {}),
      message: json['message'] ?? '',
      imageUrl: localImage ?? json['image_url'],
    );
  }

  Map<String, dynamic> toJson() => {
    'status': status,
    'case_number': caseNumber,
    'crop_type': cropType,
    'is_supported': isSupported,
    'confidence_band': confidenceBand,
    'confidence_score': confidenceScore,
    'diagnosis': diagnosis,
    'severity': severity,
    'knowledge_doc_id': knowledgeDocId,
    'vetted_advice': vettedAdvice,
    'message': message,
    'image_url': imageUrl,
    'timestamp': timestamp.toIso8601String(),
  };
}
