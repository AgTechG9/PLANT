namespace Plant.AdminApi.Models;

public enum UserRole
{
    Admin,
    Agent,
    Farmer
}

public class User
{
    public int Id { get; set; }
    public string Username { get; set; } = string.Empty;
    public string HashedPassword { get; set; } = string.Empty;
    public string Salt { get; set; } = string.Empty;
    public string FullName { get; set; } = string.Empty;
    public UserRole Role { get; set; } = UserRole.Agent;
    public string? County { get; set; }
    public string? PhoneNumber { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}

public class Farmer
{
    public int Id { get; set; }
    public string FullName { get; set; } = string.Empty;
    public string PhoneNumber { get; set; } = string.Empty;
    public string County { get; set; } = string.Empty;
    public string District { get; set; } = string.Empty;
    public string PrimaryCrop { get; set; } = "Cassava";
    public double FarmSizeAcres { get; set; } = 1.0;
    public string PreferredLanguage { get; set; } = "Liberian English";
    public DateTime RegisteredAt { get; set; } = DateTime.UtcNow;
}

public class ScanCase
{
    public int Id { get; set; }
    public string CaseNumber { get; set; } = string.Empty;
    public int? FarmerId { get; set; }
    public string CropType { get; set; } = string.Empty;
    public string? DiseaseDetected { get; set; }
    public double Confidence { get; set; }
    public string Status { get; set; } = "FLAGGED"; // RESOLVED, FLAGGED, ESCALATED
    public string? ImageUrl { get; set; }
    public string? OfficerNotes { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? ResolvedAt { get; set; }
}

public class KnowledgeItem
{
    public int Id { get; set; }
    public string Title { get; set; } = string.Empty;
    public string Crop { get; set; } = string.Empty;
    public string Category { get; set; } = string.Empty;
    public string Content { get; set; } = string.Empty;
    public string Source { get; set; } = "CARI Suakoko";
    public DateTime LastUpdated { get; set; } = DateTime.UtcNow;
}
