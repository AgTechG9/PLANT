using Plant.DesktopAdmin;

var client = new ApiClient();

Console.Clear();
Console.ForegroundColor = ConsoleColor.Green;
Console.WriteLine(@"
======================================================================
  ____  _        _    _   _ _____     _    ___ 
 |  _ \| |      / \  | \ | |_   _|   / \  |_ _|
 | |_) | |     / _ \ |  \| | | |    / _ \  | | 
 |  __/| |___ / ___ \| |\  | | |   / ___ \ | | 
 |_|   |_____/_/   \_\_| \_| |_|  /_/   \_\___|
  
  DESKTOP ADMIN TRIAGE WORKSTATION (.NET 10)
  Ministry of Agriculture · CARI Suakoko Operational Hub
======================================================================");
Console.ResetColor();

while (true)
{
    Console.WriteLine();
    Console.ForegroundColor = ConsoleColor.Cyan;
    Console.WriteLine("[MENU] Choose an operation:");
    Console.ResetColor();
    Console.WriteLine("  1. Inspect Master Triage Queue (Escalated <65% & Blurry Scans)");
    Console.WriteLine("  2. View Enrolled Farmers Directory (Bong, Nimba, Lofa)");
    Console.WriteLine("  3. Check System Telemetry & Gateway Health");
    Console.WriteLine("  4. Exit");
    Console.Write("\nSelect option (1-4): ");

    var choice = Console.ReadLine()?.Trim();

    if (choice == "1")
    {
        Console.ForegroundColor = ConsoleColor.Yellow;
        Console.WriteLine("\n--> Fetching pending escalation cases from FastAPI (Rule SCAN-04)...");
        Console.ResetColor();

        var cases = await client.GetPendingCasesAsync();
        if (cases.Count == 0)
        {
            Console.WriteLine("No pending escalated cases. Triage queue is clear!");
        }
        else
        {
            Console.WriteLine($"Found {cases.Count} pending case(s):");
            Console.WriteLine(new string('-', 70));
            foreach (var c in cases)
            {
                Console.WriteLine($"Case: {c.CaseNumber} | Farmer: {c.FarmerName} | Crop: {c.CropType}");
                Console.WriteLine($"AI Finding: {c.AiDiagnosis} (Confidence: {c.AiConfidence * 100:0}%)");
                Console.WriteLine($"Severity: {c.Severity} | Status: {c.Status}");
                Console.WriteLine(new string('-', 70));
            }

            Console.Write("\nEnter Case ID to resolve (or press Enter to skip): ");
            var caseId = Console.ReadLine()?.Trim();
            if (!string.IsNullOrEmpty(caseId))
            {
                Console.Write("Enter Officer Verification Note: ");
                var note = Console.ReadLine() ?? "Verified by CARI Officer";
                Console.Write("Enter 160-char SMS Resolution: ");
                var resolution = Console.ReadLine() ?? "CARI Alert: Uproot diseased plant. Spray neem extract.";

                var success = await client.ResolveCaseAsync(caseId, note, resolution);
                if (success)
                {
                    Console.ForegroundColor = ConsoleColor.Green;
                    Console.WriteLine("✓ Case resolved and 160-char SMS dispatched to farmer!");
                    Console.ResetColor();
                }
                else
                {
                    Console.ForegroundColor = ConsoleColor.Red;
                    Console.WriteLine("Failed to resolve case. Check backend connection.");
                    Console.ResetColor();
                }
            }
        }
    }
    else if (choice == "2")
    {
        Console.ForegroundColor = ConsoleColor.Yellow;
        Console.WriteLine("\n--> Querying Farmer Directory...");
        Console.ResetColor();

        var farmers = await client.GetFarmersAsync();
        Console.WriteLine($"Total Farmers: {farmers.Count}");
        foreach (var f in farmers)
        {
            Console.WriteLine($"• {f.FullName,-18} | {f.County,-8} ({f.District,-12}) | {f.Gender,-6} | {f.PhoneNumber}");
        }
    }
    else if (choice == "3")
    {
        Console.ForegroundColor = ConsoleColor.Green;
        Console.WriteLine("\n--> Checking Telemetry: Backend http://localhost:8000/api/v1/health ...");
        try
        {
            using var http = new HttpClient();
            var res = await http.GetStringAsync("http://localhost:8000/api/v1/health");
            Console.WriteLine(res);
        }
        catch (Exception ex)
        {
            Console.ForegroundColor = ConsoleColor.Red;
            Console.WriteLine($"Error reaching backend: {ex.Message}");
        }
        Console.ResetColor();
    }
    else if (choice == "4")
    {
        Console.WriteLine("Goodbye, Officer!");
        break;
    }
    else
    {
        Console.WriteLine("Invalid selection.");
    }
}
