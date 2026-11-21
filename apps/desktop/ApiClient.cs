using System.Net.Http.Json;
using System.Text.Json;
using System.Text.Json.Serialization;

namespace Plant.DesktopAdmin;

// --- DTO Models matching FastAPI schemas ---

public class DatabaseHealth
{
    [JsonPropertyName("status")]
    public string Status { get; set; } = string.Empty;

    [JsonPropertyName("latency_ms")]
    public double LatencyMs { get; set; }

    [JsonPropertyName("engine")]
    public string Engine { get; set; } = string.Empty;
}

public class AiServiceHealth
{
    [JsonPropertyName("status")]
    public string Status { get; set; } = string.Empty;

    [JsonPropertyName("model")]
    public string Model { get; set; } = string.Empty;

    [JsonPropertyName("confidence_threshold")]
    public double ConfidenceThreshold { get; set; }

    [JsonPropertyName("supported_crops")]
    public List<string> SupportedCrops { get; set; } = new();
}

public class SmsServiceHealth
{
    [JsonPropertyName("status")]
    public string Status { get; set; } = string.Empty;

    [JsonPropertyName("gateway")]
    public string Gateway { get; set; } = string.Empty;

    [JsonPropertyName("queue_depth")]
    public int QueueDepth { get; set; }

    [JsonPropertyName("sms_rate_limit_per_min")]
    public int RateLimitPerMin { get; set; }
}

public class HealthResponse
{
    [JsonPropertyName("status")]
    public string Status { get; set; } = string.Empty;

    [JsonPropertyName("version")]
    public string Version { get; set; } = string.Empty;

    [JsonPropertyName("database")]
    public DatabaseHealth? Database { get; set; }

    [JsonPropertyName("ai_service")]
    public AiServiceHealth? AiService { get; set; }

    [JsonPropertyName("sms_service")]
    public SmsServiceHealth? SmsService { get; set; }

    [JsonPropertyName("timestamp")]
    public DateTime? Timestamp { get; set; }
}

public class FarmerMetrics
{
    [JsonPropertyName("total_farmers")]
    public int TotalFarmers { get; set; }

    [JsonPropertyName("female_farmers")]
    public int FemaleFarmers { get; set; }

    [JsonPropertyName("female_ratio_pct")]
    public double FemaleRatioPct { get; set; }

    [JsonPropertyName("livestock_interest_count")]
    public int LivestockInterestCount { get; set; }

    [JsonPropertyName("by_county")]
    public Dictionary<string, int> ByCounty { get; set; } = new();

    [JsonPropertyName("by_language")]
    public Dictionary<string, int> ByLanguage { get; set; } = new();
}

public class FarmerItem
{
    [JsonPropertyName("id")]
    public string Id { get; set; } = string.Empty;

    [JsonPropertyName("full_name")]
    public string FullName { get; set; } = string.Empty;

    [JsonPropertyName("phone_number")]
    public string PhoneNumber { get; set; } = string.Empty;

    [JsonPropertyName("county")]
    public string County { get; set; } = string.Empty;

    [JsonPropertyName("district")]
    public string District { get; set; } = string.Empty;

    [JsonPropertyName("gender")]
    public string Gender { get; set; } = string.Empty;

    [JsonPropertyName("preferred_language")]
    public string PreferredLanguage { get; set; } = string.Empty;

    [JsonPropertyName("consent_status")]
    public string ConsentStatus { get; set; } = string.Empty;

    [JsonPropertyName("livestock_interest")]
    public bool LivestockInterest { get; set; }
}

public class CaseItem
{
    [JsonPropertyName("id")]
    public string Id { get; set; } = string.Empty;

    [JsonPropertyName("case_number")]
    public string CaseNumber { get; set; } = string.Empty;

    [JsonPropertyName("farmer_name")]
    public string FarmerName { get; set; } = string.Empty;

    [JsonPropertyName("farmer_phone")]
    public string FarmerPhone { get; set; } = string.Empty;

    [JsonPropertyName("crop_type")]
    public string CropType { get; set; } = string.Empty;

    [JsonPropertyName("image_url")]
    public string ImageUrl { get; set; } = string.Empty;

    [JsonPropertyName("ai_diagnosis")]
    public string AiDiagnosis { get; set; } = string.Empty;

    [JsonPropertyName("ai_confidence")]
    public double AiConfidence { get; set; }

    [JsonPropertyName("severity")]
    public string Severity { get; set; } = string.Empty;

    [JsonPropertyName("is_blurry")]
    public bool IsBlurry { get; set; }

    [JsonPropertyName("status")]
    public string Status { get; set; } = string.Empty;

    [JsonPropertyName("officer_notes")]
    public string? OfficerNotes { get; set; }

    [JsonPropertyName("officer_resolution")]
    public string? OfficerResolution { get; set; }

    [JsonPropertyName("resolution_sms_sent")]
    public bool ResolutionSmsSent { get; set; }

    [JsonPropertyName("created_at")]
    public string? CreatedAt { get; set; }
}

public class KnowledgeItem
{
    [JsonPropertyName("id")]
    public string Id { get; set; } = string.Empty;

    [JsonPropertyName("doc_id")]
    public string DocId { get; set; } = string.Empty;

    [JsonPropertyName("crop")]
    public string Crop { get; set; } = string.Empty;

    [JsonPropertyName("condition_name")]
    public string ConditionName { get; set; } = string.Empty;

    [JsonPropertyName("symptom_description")]
    public string SymptomDescription { get; set; } = string.Empty;

    [JsonPropertyName("cultural_control")]
    public string CulturalControl { get; set; } = string.Empty;

    [JsonPropertyName("chemical_control")]
    public string ChemicalControl { get; set; } = string.Empty;

    [JsonPropertyName("vetted_sms_template")]
    public string VettedSmsTemplate { get; set; } = string.Empty;

    [JsonPropertyName("source_org")]
    public string SourceOrg { get; set; } = string.Empty;

    [JsonPropertyName("approved_by")]
    public string ApprovedBy { get; set; } = string.Empty;
}

public class SmsLogItem
{
    [JsonPropertyName("id")]
    public string Id { get; set; } = string.Empty;

    [JsonPropertyName("recipient_phone")]
    public string RecipientPhone { get; set; } = string.Empty;

    [JsonPropertyName("county")]
    public string County { get; set; } = string.Empty;

    [JsonPropertyName("message_text")]
    public string MessageText { get; set; } = string.Empty;

    [JsonPropertyName("char_count")]
    public int CharCount { get; set; }

    [JsonPropertyName("status")]
    public string Status { get; set; } = string.Empty;

    [JsonPropertyName("sent_at")]
    public string? SentAt { get; set; }
}

public class BroadcastResponse
{
    [JsonPropertyName("broadcast_id")]
    public string BroadcastId { get; set; } = string.Empty;

    [JsonPropertyName("targeted_county")]
    public string TargetedCounty { get; set; } = string.Empty;

    [JsonPropertyName("messages_dispatched")]
    public int MessagesDispatched { get; set; }

    [JsonPropertyName("status")]
    public string Status { get; set; } = string.Empty;
}

public class UssdResponse
{
    [JsonPropertyName("message")]
    public string Message { get; set; } = string.Empty;

    [JsonPropertyName("continueSession")]
    public bool ContinueSession { get; set; }
}

public class DiagnoseResponse
{
    [JsonPropertyName("status")]
    public string Status { get; set; } = string.Empty;

    [JsonPropertyName("case_number")]
    public string? CaseNumber { get; set; }

    [JsonPropertyName("crop_type")]
    public string CropType { get; set; } = string.Empty;

    [JsonPropertyName("is_supported")]
    public bool IsSupported { get; set; }

    [JsonPropertyName("confidence_band")]
    public string? ConfidenceBand { get; set; }

    [JsonPropertyName("confidence_score")]
    public double ConfidenceScore { get; set; }

    [JsonPropertyName("diagnosis")]
    public string Diagnosis { get; set; } = string.Empty;

    [JsonPropertyName("severity")]
    public string Severity { get; set; } = string.Empty;

    [JsonPropertyName("knowledge_doc_id")]
    public string? KnowledgeDocId { get; set; }

    [JsonPropertyName("message")]
    public string Message { get; set; } = string.Empty;

    [JsonPropertyName("vetted_advice")]
    public JsonElement? VettedAdvice { get; set; }
}

public class ApiClient
{
    private readonly HttpClient _client;
    public string BaseUrl { get; }

    public ApiClient(string? baseUrl = null)
    {
        BaseUrl = baseUrl 
            ?? Environment.GetEnvironmentVariable("PLANT_API_URL") 
            ?? "http://localhost:8000/api/v1";

        if (!BaseUrl.EndsWith("/"))
        {
            BaseUrl += "/";
        }

        _client = new HttpClient 
        { 
            BaseAddress = new Uri(BaseUrl),
            Timeout = TimeSpan.FromSeconds(15)
        };
    }

    // --- Module 1: Mission Control & Telemetry ---

    public async Task<HealthResponse?> GetHealthAsync()
    {
        try
        {
            return await _client.GetFromJsonAsync<HealthResponse>("health");
        }
        catch
        {
            return null;
        }
    }

    public async Task<FarmerMetrics?> GetFarmerMetricsAsync()
    {
        try
        {
            return await _client.GetFromJsonAsync<FarmerMetrics>("farmers/metrics");
        }
        catch
        {
            return null;
        }
    }

    // --- Module 2: Master Escalations & Overrides ---

    public async Task<List<CaseItem>> GetCasesAsync(string status = "PENDING_ESCALATION", string? crop = null)
    {
        try
        {
            var url = $"cases?status={Uri.EscapeDataString(status)}";
            if (!string.IsNullOrEmpty(crop) && crop != "ALL")
            {
                url += $"&crop_type={Uri.EscapeDataString(crop)}";
            }
            var res = await _client.GetFromJsonAsync<List<CaseItem>>(url);
            return res ?? new List<CaseItem>();
        }
        catch
        {
            return new List<CaseItem>();
        }
    }

    public async Task<bool> ResolveCaseAsync(string id, string notes, string resolution, bool sendSms = true)
    {
        try
        {
            var payload = new
            {
                officer_notes = notes,
                officer_resolution = resolution,
                send_sms_to_farmer = sendSms
            };
            var res = await _client.PatchAsJsonAsync($"cases/{id}", payload);
            return res.IsSuccessStatusCode;
        }
        catch
        {
            return false;
        }
    }

    // --- Module 3: Farmer Directory & Broadcast ---

    public async Task<List<FarmerItem>> GetFarmersAsync(string? county = null, string? search = null)
    {
        try
        {
            var url = "farmers";
            var queryParams = new List<string>();
            if (!string.IsNullOrEmpty(county) && county != "ALL")
                queryParams.Add($"county={Uri.EscapeDataString(county)}");
            if (!string.IsNullOrEmpty(search))
                queryParams.Add($"search={Uri.EscapeDataString(search)}");

            if (queryParams.Count > 0)
                url += "?" + string.Join("&", queryParams);

            var res = await _client.GetFromJsonAsync<List<FarmerItem>>(url);
            return res ?? new List<FarmerItem>();
        }
        catch
        {
            return new List<FarmerItem>();
        }
    }

    public async Task<BroadcastResponse?> DispatchBroadcastAsync(string county, string messageText)
    {
        try
        {
            var payload = new
            {
                county = county,
                message_text = messageText
            };
            var res = await _client.PostAsJsonAsync("sms/broadcast", payload);
            if (res.IsSuccessStatusCode)
            {
                return await res.Content.ReadFromJsonAsync<BroadcastResponse>();
            }
            return null;
        }
        catch
        {
            return null;
        }
    }

    // --- Module 4: USSD Engine & SMS Testbench ---

    public async Task<UssdResponse?> CallUssdAsync(string sessionId, string phoneNumber, string text)
    {
        try
        {
            var payload = new
            {
                sessionId = sessionId,
                phoneNumber = phoneNumber,
                serviceCode = "*123#",
                text = text
            };
            var res = await _client.PostAsJsonAsync("ussd", payload);
            if (res.IsSuccessStatusCode)
            {
                return await res.Content.ReadFromJsonAsync<UssdResponse>();
            }
            return null;
        }
        catch
        {
            return null;
        }
    }

    public async Task<List<SmsLogItem>> GetSmsLogsAsync(int limit = 15)
    {
        try
        {
            var res = await _client.GetFromJsonAsync<List<SmsLogItem>>($"sms/logs?limit={limit}");
            return res ?? new List<SmsLogItem>();
        }
        catch
        {
            return new List<SmsLogItem>();
        }
    }

    // --- Module 5: Vetted CARI Knowledge Base ---

    public async Task<List<KnowledgeItem>> GetKnowledgeAsync(string? crop = null, string? search = null)
    {
        try
        {
            var url = "knowledge";
            var queryParams = new List<string>();
            if (!string.IsNullOrEmpty(crop) && crop != "ALL")
                queryParams.Add($"crop={Uri.EscapeDataString(crop)}");
            if (!string.IsNullOrEmpty(search))
                queryParams.Add($"search={Uri.EscapeDataString(search)}");

            if (queryParams.Count > 0)
                url += "?" + string.Join("&", queryParams);

            var res = await _client.GetFromJsonAsync<List<KnowledgeItem>>(url);
            return res ?? new List<KnowledgeItem>();
        }
        catch
        {
            return new List<KnowledgeItem>();
        }
    }

    // --- Module 6: AI Diagnostics & Safety Validator ---

    public async Task<DiagnoseResponse?> RunDiagnosticsAsync(string cropType, string imageUrl = "mock_leaf_scan")
    {
        try
        {
            var payload = new
            {
                crop_type = cropType,
                image_url = imageUrl
            };
            var res = await _client.PostAsJsonAsync("diagnose", payload);
            if (res.IsSuccessStatusCode)
            {
                return await res.Content.ReadFromJsonAsync<DiagnoseResponse>();
            }
            return null;
        }
        catch
        {
            return null;
        }
    }
}
