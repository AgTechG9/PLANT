using Plant.AdminApi.Models;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddOpenApi();
builder.Services.AddCors(options =>
{
    options.AddDefaultPolicy(policy =>
    {
        policy.AllowAnyOrigin().AllowAnyHeader().AllowAnyMethod();
    });
});

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
}

app.UseCors();

// In-memory data store for quick development & hackathon demo
var farmers = new List<Farmer>
{
    new() { Id = 1, FullName = "Korto Flomo", PhoneNumber = "+231770123456", County = "Bong", District = "Suakoko", PrimaryCrop = "Cassava", FarmSizeAcres = 2.5, PreferredLanguage = "Kpelle" },
    new() { Id = 2, FullName = "Emmanuel Tokpa", PhoneNumber = "+231886234567", County = "Nimba", District = "Sanniquellie-Mah", PrimaryCrop = "Cassava", FarmSizeAcres = 4.0, PreferredLanguage = "Liberian English" },
    new() { Id = 3, FullName = "Fatu Kamara", PhoneNumber = "+231775345678", County = "Lofa", District = "Voinjama", PrimaryCrop = "Pepper", FarmSizeAcres = 1.2, PreferredLanguage = "Liberian English" }
};

var cases = new List<ScanCase>
{
    new() { Id = 1, CaseNumber = "CASE-2026-0001", FarmerId = 1, CropType = "Cassava", DiseaseDetected = "Cassava Mosaic Disease (CMD)", Confidence = 0.92, Status = "FLAGGED" },
    new() { Id = 2, CaseNumber = "CASE-2026-0002", FarmerId = 2, CropType = "Cassava", DiseaseDetected = "Cassava Brown Streak Disease (CBSD)", Confidence = 0.48, Status = "ESCALATED" },
    new() { Id = 3, CaseNumber = "CASE-2026-0003", FarmerId = 3, CropType = "Pepper", DiseaseDetected = "Pepper Anthracnose", Confidence = 0.88, Status = "RESOLVED", ResolvedAt = DateTime.UtcNow }
};

app.MapGet("/health", () => Results.Ok(new
{
    status = "healthy",
    service = "Plant.AdminApi (.NET 10)",
    timestamp = DateTime.UtcNow
}));

app.MapGet("/api/v1/farmers", () => Results.Ok(farmers));

app.MapGet("/api/v1/cases", () => Results.Ok(cases));

app.MapGet("/api/v1/cases/{id:int}", (int id) =>
{
    var item = cases.FirstOrDefault(c => c.Id == id);
    return item is not null ? Results.Ok(item) : Results.NotFound();
});

app.MapPatch("/api/v1/cases/{id:int}", (int id, ScanCase update) =>
{
    var existing = cases.FirstOrDefault(c => c.Id == id);
    if (existing == null) return Results.NotFound();
    
    if (!string.IsNullOrEmpty(update.Status)) existing.Status = update.Status;
    if (!string.IsNullOrEmpty(update.OfficerNotes)) existing.OfficerNotes = update.OfficerNotes;
    if (update.Status == "RESOLVED") existing.ResolvedAt = DateTime.UtcNow;
    
    return Results.Ok(existing);
});

app.Run();
