using System.Net.Http.Json;
using System.Text.Json;
using System.Text.Json.Serialization;

namespace Plant.DesktopAdmin;

public class CaseItem
{
    [JsonPropertyName("id")]
    public string Id { get; set; } = string.Empty;

    [JsonPropertyName("case_number")]
    public string CaseNumber { get; set; } = string.Empty;

    [JsonPropertyName("farmer_name")]
    public string FarmerName { get; set; } = string.Empty;

    [JsonPropertyName("crop_type")]
    public string CropType { get; set; } = string.Empty;

    [JsonPropertyName("ai_diagnosis")]
    public string AiDiagnosis { get; set; } = string.Empty;

    [JsonPropertyName("ai_confidence")]
    public double AiConfidence { get; set; }

    [JsonPropertyName("severity")]
    public string Severity { get; set; } = string.Empty;

    [JsonPropertyName("status")]
    public string Status { get; set; } = string.Empty;
}

public class FarmerItem
{
    [JsonPropertyName("full_name")]
    public string FullName { get; set; } = string.Empty;

    [JsonPropertyName("county")]
    public string County { get; set; } = string.Empty;

    [JsonPropertyName("district")]
    public string District { get; set; } = string.Empty;

    [JsonPropertyName("gender")]
    public string Gender { get; set; } = string.Empty;

    [JsonPropertyName("phone_number")]
    public string PhoneNumber { get; set; } = string.Empty;
}

public class ApiClient
{
    private readonly HttpClient _client;

    public ApiClient(string baseUrl = "http://localhost:8000/api/v1")
    {
        _client = new HttpClient { BaseAddress = new Uri(baseUrl) };
    }

    public async Task<List<CaseItem>> GetPendingCasesAsync()
    {
        try
        {
            var res = await _client.GetFromJsonAsync<List<CaseItem>>("cases?status=PENDING_ESCALATION");
            return res ?? new List<CaseItem>();
        }
        catch
        {
            return new List<CaseItem>();
        }
    }

    public async Task<List<FarmerItem>> GetFarmersAsync()
    {
        try
        {
            var res = await _client.GetFromJsonAsync<List<FarmerItem>>("farmers");
            return res ?? new List<FarmerItem>();
        }
        catch
        {
            return new List<FarmerItem>();
        }
    }

    public async Task<bool> ResolveCaseAsync(string id, string notes, string resolution)
    {
        try
        {
            var payload = new
            {
                officer_notes = notes,
                officer_resolution = resolution,
                send_sms_to_farmer = true
            };
            var res = await _client.PatchAsJsonAsync($"cases/{id}", payload);
            return res.IsSuccessStatusCode;
        }
        catch
        {
            return false;
        }
    }
}
