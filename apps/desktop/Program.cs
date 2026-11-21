using System.Text.Json;
using Plant.DesktopAdmin;

string currentApiUrl = Environment.GetEnvironmentVariable("PLANT_API_URL") ?? "http://localhost:8000/api/v1";
var client = new ApiClient(currentApiUrl);

void PrintHeader()
{
    Console.Clear();
    Console.ForegroundColor = ConsoleColor.DarkGreen;
    Console.WriteLine(@"
 ╔══════════════════════════════════════════════════════════════════════════════╗
 ║      ____  _        _    _   _ _____     _    ___                            ║
 ║     |  _ \| |      / \  | \ | |_   _|   / \  |_ _|                           ║
 ║     | |_) | |     / _ \ |  \| | | |    / _ \  | |                            ║
 ║     |  __/| |___ / ___ \| |\  | | |   / ___ \ | |                            ║
 ║     |_|   |_____/_/   \_\_| \_| |_|  /_/   \_\___|                           ║
 ║                                                                              ║
 ║     DESKTOP ADMIN MISSION CONTROL & TRIAGE WORKSTATION (.NET 10)             ║
 ║     Ministry of Agriculture · CARI Suakoko Operational Hub                   ║
 ╚══════════════════════════════════════════════════════════════════════════════╝");
    Console.ResetColor();
    Console.ForegroundColor = ConsoleColor.DarkGray;
    Console.WriteLine($" Target API: {client.BaseUrl} | Mode: Internal Dev & Operations");
    Console.WriteLine(new string('─', 80));
    Console.ResetColor();
}

void PauseForUser()
{
    Console.ForegroundColor = ConsoleColor.DarkGray;
    Console.Write("\nPress [Enter] to return to main menu...");
    Console.ResetColor();
    Console.ReadLine();
}

while (true)
{
    PrintHeader();

    Console.ForegroundColor = ConsoleColor.Cyan;
    Console.WriteLine(" CORE MODULES (AgTech Hackathon 2026 Blueprint):");
    Console.ResetColor();
    Console.WriteLine("   [1] Mission Control & Health Telemetry     (System status, KPIs, quotas, live events)");
    Console.WriteLine("   [2] Master Escalation Workbench            (Rule SCAN-04 triage: <65% confidence/blurry)");
    Console.WriteLine("   [3] Farmer Directory & Emergency Broadcast (Bong/Nimba/Lofa, STOP consent, SMS dispatch)");
    Console.WriteLine("   [4] USSD Engine & SMS Testbench            (Virtual *123# interactive dialer & packet sniffer)");
    Console.WriteLine("   [5] Vetted CARI Knowledge Base (RAG)       (Rule ADV-01 audit: CARI-CAS-001, CARI-PEP-001)");
    Console.WriteLine("   [6] AI Diagnostics & Safety Validator      (Rule SCAN-03 guardrail: Unsupported crop warning)");
    Console.WriteLine("   [7] Configure API Target Endpoint          (Toggle Local vs Cloud Railway/Render URL)");
    Console.WriteLine("   [8] Exit Workstation");

    Console.ForegroundColor = ConsoleColor.Yellow;
    Console.Write("\nSelect Module (1-8): ");
    Console.ResetColor();

    var choice = Console.ReadLine()?.Trim();

    if (choice == "1")
    {
        // ==========================================
        // MODULE 1: MISSION CONTROL & TELEMETRY
        // ==========================================
        Console.Clear();
        Console.ForegroundColor = ConsoleColor.Green;
        Console.WriteLine("\n[MODULE 1] MISSION CONTROL & SYSTEM HEALTH TELEMETRY");
        Console.WriteLine(new string('=', 70));
        Console.ResetColor();

        Console.WriteLine("Pinging Gateway & Services...");
        var health = await client.GetHealthAsync();
        var metrics = await client.GetFarmerMetricsAsync();
        var logs = await client.GetSmsLogsAsync(5);

        if (health != null)
        {
            Console.ForegroundColor = ConsoleColor.White;
            Console.WriteLine($"\n• Overall Status:     [{(health.Status == "healthy" ? "HEALTHY" : "DEGRADED")}] (Version: {health.Version})");
            Console.WriteLine($"• Database Engine:    {health.Database?.Engine ?? "N/A"} | Latency: {health.Database?.LatencyMs:0.0}ms");
            Console.WriteLine($"• Vision AI Model:    {health.AiService?.Model ?? "N/A"} (Abstention Threshold: {health.AiService?.ConfidenceThreshold * 100:0}%)");
            Console.WriteLine($"• SMS Gateway:        {health.SmsService?.Gateway ?? "N/A"} (Queue Depth: {health.SmsService?.QueueDepth}, Rate Limit: {health.SmsService?.RateLimitPerMin}/min)");
            Console.ResetColor();
        }
        else
        {
            Console.ForegroundColor = ConsoleColor.Red;
            Console.WriteLine("✗ Unable to reach API gateway. Please verify that the backend is running.");
            Console.ResetColor();
        }

        if (metrics != null)
        {
            Console.ForegroundColor = ConsoleColor.Cyan;
            Console.WriteLine("\nNATIONAL SMALLHOLDER KPIS:");
            Console.ResetColor();
            Console.WriteLine($"  • Total Enrolled Farmers:  {metrics.TotalFarmers}");
            
            // 54% Female Quota Check
            Console.Write($"  • Female Farmers Ratio:    {metrics.FemaleRatioPct:F1}% ({metrics.FemaleFarmers}/{metrics.TotalFarmers}) ");
            if (metrics.FemaleRatioPct >= 50.0)
            {
                Console.ForegroundColor = ConsoleColor.Green;
                Console.WriteLine("[✓ 54% GENDER TARGET ON TRACK]");
            }
            else
            {
                Console.ForegroundColor = ConsoleColor.Yellow;
                Console.WriteLine("[! ACTION NEEDED FOR 54% TARGET]");
            }
            Console.ResetColor();

            // Rule REG-03 Livestock Counter
            Console.ForegroundColor = ConsoleColor.Magenta;
            Console.WriteLine($"  • Rule REG-03 Livestock 'Coming Soon' Interest: {metrics.LivestockInterestCount} farmer(s)");
            Console.ResetColor();

            Console.WriteLine($"  • County Distribution:     {string.Join(", ", metrics.ByCounty.Select(kv => $"{kv.Key}: {kv.Value}"))}");
            Console.WriteLine($"  • Language Distribution:   {string.Join(", ", metrics.ByLanguage.Select(kv => $"{kv.Key}: {kv.Value}"))}");
        }

        Console.ForegroundColor = ConsoleColor.Cyan;
        Console.WriteLine("\nRECENT TELEMETRY & SMS PACKETS (LAST 5):");
        Console.ResetColor();
        if (logs.Count == 0)
        {
            Console.WriteLine("  No outbound SMS logs recorded yet.");
        }
        else
        {
            foreach (var log in logs)
            {
                Console.WriteLine($"  [{log.SentAt?[11..19] ?? "LIVE"}] To: {log.RecipientPhone,-15} ({log.County}) | Bytes: {log.CharCount}/160 | Status: {log.Status}");
                Console.ForegroundColor = ConsoleColor.DarkGray;
                Console.WriteLine($"    \"{log.MessageText}\"");
                Console.ResetColor();
            }
        }

        PauseForUser();
    }
    else if (choice == "2")
    {
        // ==========================================
        // MODULE 2: MASTER ESCALATION WORKBENCH
        // ==========================================
        Console.Clear();
        Console.ForegroundColor = ConsoleColor.Red;
        Console.WriteLine("\n[MODULE 2] MASTER ESCALATION TRIAGE WORKBENCH (Rule SCAN-04)");
        Console.WriteLine("Review flagged scans (<65% AI confidence or blurry leaves) & dispatch 160-char SMS");
        Console.WriteLine(new string('=', 75));
        Console.ResetColor();

        Console.WriteLine("Fetching pending escalation queue...");
        var cases = await client.GetCasesAsync("PENDING_ESCALATION");

        if (cases.Count == 0)
        {
            Console.ForegroundColor = ConsoleColor.Green;
            Console.WriteLine("\n✓ Triage queue is clear! All escalated scans have been verified by CARI officers.");
            Console.ResetColor();
        }
        else
        {
            Console.ForegroundColor = ConsoleColor.Yellow;
            Console.WriteLine($"\nFound {cases.Count} scan(s) requiring manual officer review:");
            Console.ResetColor();
            Console.WriteLine(new string('-', 75));

            int idx = 1;
            foreach (var c in cases)
            {
                Console.ForegroundColor = ConsoleColor.White;
                Console.Write($"[{idx}] Case: {c.CaseNumber} | Crop: {c.CropType,-7} | Farmer: {c.FarmerName} ({c.FarmerPhone})\n");
                Console.ResetColor();
                Console.ForegroundColor = ConsoleColor.Red;
                Console.WriteLine($"    AI Finding:    {c.AiDiagnosis}");
                Console.WriteLine($"    Confidence:    {c.AiConfidence * 100:0.0}% (Abstained <65%) | Severity: {c.Severity} | Blurry: {(c.IsBlurry ? "YES (Scan Flagged)" : "No")}");
                Console.ForegroundColor = ConsoleColor.DarkGray;
                Console.WriteLine($"    Leaf Image:    {c.ImageUrl}");
                Console.WriteLine($"    System Notes:  {c.OfficerNotes}");
                Console.ResetColor();
                Console.WriteLine(new string('-', 75));
                idx++;
            }

            Console.ForegroundColor = ConsoleColor.Cyan;
            Console.Write("\nEnter Case # to review and resolve (or press Enter to return): ");
            Console.ResetColor();
            var pickStr = Console.ReadLine()?.Trim();

            if (int.TryParse(pickStr, out int pick) && pick >= 1 && pick <= cases.Count)
            {
                var targetCase = cases[pick - 1];
                Console.Clear();
                Console.ForegroundColor = ConsoleColor.Yellow;
                Console.WriteLine($"\n--- INSPECTION WORKBENCH: CASE {targetCase.CaseNumber} ---");
                Console.ResetColor();
                Console.WriteLine($"Crop: {targetCase.CropType} | Farmer: {targetCase.FarmerName} ({targetCase.FarmerPhone})");
                Console.WriteLine($"AI Diagnosis: {targetCase.AiDiagnosis} ({targetCase.AiConfidence * 100:0}% confidence)");

                Console.ForegroundColor = ConsoleColor.Cyan;
                Console.WriteLine("\nSelect Resolution Option:");
                Console.ResetColor();
                Console.WriteLine("  1. Apply CARI-CAS-001 Vetted Advice (Cassava Mosaic Disease: Uproot & Spray Neem)");
                Console.WriteLine("  2. Apply CARI-PEP-001 Vetted Advice (Pepper Anthracnose: Remove Pods & Spray Mancozeb)");
                Console.WriteLine("  3. Request New Photo (Image too blurry or bad lighting)");
                Console.WriteLine("  4. Custom Officer Diagnostic Note & SMS");
                Console.Write("\nChoice (1-4): ");

                var opt = Console.ReadLine()?.Trim();
                string note = "";
                string resolution = "";

                if (opt == "1")
                {
                    note = "Verified by CARI Officer: Early chlorotic mosaic confirmed.";
                    resolution = "CARI Suakoko Alert: CMD detected. Uproot & burn diseased cassava plant immediately. Use certified stems. Call 4410.";
                }
                else if (opt == "2")
                {
                    note = "Verified by CARI Officer: Anthracnose sunken lesion confirmed.";
                    resolution = "CARI Advisory: Pepper Anthracnose. Remove rotting pods. Spray Mancozeb (2 tbsp/15L water). Water at base only.";
                }
                else if (opt == "3")
                {
                    note = "Verified by CARI Officer: Image blurry, leaf veins unclear.";
                    resolution = "CARI Notice: Leaf photo was blurry. Please rescan your crop in direct sunlight focusing on the top leaves.";
                }
                else
                {
                    Console.Write("\nEnter Officer Diagnostic Note: ");
                    note = Console.ReadLine() ?? "Verified by CARI Extension Officer.";
                    Console.Write("Enter 160-char SMS Resolution to Farmer: ");
                    resolution = Console.ReadLine() ?? "CARI Alert: Please visit the Suakoko Extension Station for treatment.";
                }

                // Character count verification
                Console.WriteLine($"\nMessage length: {resolution.Length}/160 characters");
                if (resolution.Length > 160)
                {
                    Console.ForegroundColor = ConsoleColor.Red;
                    Console.WriteLine("⚠️ WARNING: Resolution exceeds 160-character GSM SMS limit!");
                    Console.ResetColor();
                }

                Console.ForegroundColor = ConsoleColor.Yellow;
                Console.Write("\nDispatch verified SMS and mark case RESOLVED? (y/n): ");
                Console.ResetColor();
                if (Console.ReadLine()?.Trim().ToLower() == "y")
                {
                    var success = await client.ResolveCaseAsync(targetCase.Id, note, resolution, sendSms: true);
                    if (success)
                    {
                        Console.ForegroundColor = ConsoleColor.Green;
                        Console.WriteLine($"\n✓ Case {targetCase.CaseNumber} successfully resolved!");
                        Console.WriteLine($"✓ 160-character verified SMS dispatched to {targetCase.FarmerPhone}");
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

        PauseForUser();
    }
    else if (choice == "3")
    {
        // ==========================================
        // MODULE 3: FARMER DIRECTORY & BROADCAST
        // ==========================================
        Console.Clear();
        Console.ForegroundColor = ConsoleColor.Cyan;
        Console.WriteLine("\n[MODULE 3] ENROLLED FARMERS DIRECTORY & EMERGENCY BROADCAST");
        Console.WriteLine("Query smallholders across Bong, Nimba, and Lofa & push verified alerts");
        Console.WriteLine(new string('=', 75));
        Console.ResetColor();

        Console.WriteLine("Options:");
        Console.WriteLine("  1. View All Enrolled Farmers");
        Console.WriteLine("  2. Filter by County (Bong / Nimba / Lofa)");
        Console.WriteLine("  3. Search by Name or Phone");
        Console.WriteLine("  4. Dispatch Emergency Weather / Pest SMS Broadcast");
        Console.Write("\nSelect action (1-4): ");

        var fOpt = Console.ReadLine()?.Trim();

        if (fOpt == "4")
        {
            Console.Clear();
            Console.ForegroundColor = ConsoleColor.Yellow;
            Console.WriteLine("\n--- EMERGENCY SMS BROADCAST DISPATCHER ---");
            Console.WriteLine("Pushes SMS to farmers with ACTIVE consent in target counties.");
            Console.ResetColor();

            Console.WriteLine("\nSelect Target County:");
            Console.WriteLine("  1. ALL Counties (National Alert)");
            Console.WriteLine("  2. Bong County");
            Console.WriteLine("  3. Nimba County");
            Console.WriteLine("  4. Lofa County");
            Console.Write("\nTarget (1-4): ");
            var cOpt = Console.ReadLine()?.Trim();
            string targetCounty = cOpt switch
            {
                "2" => "Bong",
                "3" => "Nimba",
                "4" => "Lofa",
                _ => "ALL"
            };

            Console.WriteLine($"\nTarget: {targetCounty}");
            Console.WriteLine("Sample Broadcasts:");
            Console.WriteLine("  A: CARI Agro-Met Alert: Bong & Nimba farmers expect heavy downpours. Clear runoff ditches along cassava beds to avoid root rot.");
            Console.WriteLine("  B: CARI Pest Alert: Whitefly infestation reported in Suakoko district. Inspect cassava undersides and apply neem extract spray.");
            Console.Write("\nEnter custom message or select (A/B): ");
            var msgInput = Console.ReadLine()?.Trim();
            string broadcastMsg = msgInput?.ToUpper() switch
            {
                "A" => "CARI Agro-Met Alert: Bong & Nimba farmers expect heavy downpours. Clear runoff ditches along cassava beds to avoid root rot.",
                "B" => "CARI Pest Alert: Whitefly infestation reported in Suakoko district. Inspect cassava undersides and apply neem extract spray.",
                _ => msgInput ?? ""
            };

            if (string.IsNullOrWhiteSpace(broadcastMsg))
            {
                Console.WriteLine("Broadcast cancelled (empty message).");
            }
            else if (broadcastMsg.Length > 160)
            {
                Console.ForegroundColor = ConsoleColor.Red;
                Console.WriteLine($"Error: Message length ({broadcastMsg.Length}) exceeds 160-character limit.");
                Console.ResetColor();
            }
            else
            {
                Console.ForegroundColor = ConsoleColor.Yellow;
                Console.WriteLine($"\nMessage length: {broadcastMsg.Length}/160 characters.");
                Console.Write($"Confirm dispatch to {targetCounty} farmers? (y/n): ");
                Console.ResetColor();
                if (Console.ReadLine()?.Trim().ToLower() == "y")
                {
                    var result = await client.DispatchBroadcastAsync(targetCounty, broadcastMsg);
                    if (result != null)
                    {
                        Console.ForegroundColor = ConsoleColor.Green;
                        Console.WriteLine($"\n✓ Broadcast {result.BroadcastId} successfully dispatched!");
                        Console.WriteLine($"✓ Delivered to {result.MessagesDispatched} farmer(s) in {result.TargetedCounty}.");
                        Console.ResetColor();
                    }
                    else
                    {
                        Console.ForegroundColor = ConsoleColor.Red;
                        Console.WriteLine("Failed to dispatch broadcast. Check backend logs.");
                        Console.ResetColor();
                    }
                }
            }
        }
        else
        {
            string? countyFilter = null;
            string? searchFilter = null;

            if (fOpt == "2")
            {
                Console.Write("Enter County (Bong, Nimba, Lofa): ");
                countyFilter = Console.ReadLine()?.Trim();
            }
            else if (fOpt == "3")
            {
                Console.Write("Enter Farmer Name or Phone query: ");
                searchFilter = Console.ReadLine()?.Trim();
            }

            var farmers = await client.GetFarmersAsync(countyFilter, searchFilter);
            Console.WriteLine($"\nShowing {farmers.Count} farmer(s):");
            Console.WriteLine(new string('-', 85));
            Console.WriteLine($"{"Name",-20} | {"County",-8} | {"District",-14} | {"Gender",-6} | {"Phone",-15} | {"Consent",-8} | {"Livestock",-9}");
            Console.WriteLine(new string('-', 85));
            foreach (var f in farmers)
            {
                Console.WriteLine($"{f.FullName,-20} | {f.County,-8} | {f.District,-14} | {f.Gender,-6} | {f.PhoneNumber,-15} | {f.ConsentStatus,-8} | {(f.LivestockInterest ? "YES" : "No"),-9}");
            }
            Console.WriteLine(new string('-', 85));
        }

        PauseForUser();
    }
    else if (choice == "4")
    {
        // ==========================================
        // MODULE 4: USSD ENGINE & SMS TESTBENCH
        // ==========================================
        Console.Clear();
        Console.ForegroundColor = ConsoleColor.Magenta;
        Console.WriteLine("\n[MODULE 4] USSD ENGINE & SMS TESTBENCH (Virtual *123# Dialer)");
        Console.WriteLine("Interactive USSD terminal for Orange Liberia & Lonestar MTN pitch demos");
        Console.WriteLine(new string('=', 75));
        Console.ResetColor();

        Console.WriteLine("Select Testbench Tool:");
        Console.WriteLine("  1. Launch Interactive *123# USSD Dialer Session");
        Console.WriteLine("  2. Inspect Outbound SMS Packets & Delivery Logs");
        Console.Write("\nChoice (1-2): ");

        var uOpt = Console.ReadLine()?.Trim();

        if (uOpt == "2")
        {
            Console.WriteLine("\nFetching SMS Packet Inspection Stream...");
            var logs = await client.GetSmsLogsAsync(20);
            Console.WriteLine($"\nLogged Outbound Packets ({logs.Count}):");
            Console.WriteLine(new string('-', 80));
            foreach (var l in logs)
            {
                Console.ForegroundColor = ConsoleColor.Green;
                Console.Write($"[{l.Status}] ");
                Console.ResetColor();
                Console.WriteLine($"To: {l.RecipientPhone,-15} | County: {l.County,-6} | Length: {l.CharCount}/160 | Sent: {l.SentAt}");
                Console.ForegroundColor = ConsoleColor.DarkGray;
                Console.WriteLine($"  Text: \"{l.MessageText}\"");
                Console.ResetColor();
            }
        }
        else
        {
            // Interactive USSD Dialer Session
            string sessionId = "USSD-" + Guid.NewGuid().ToString("N")[..8];
            string phone = "+231770123456";
            string currentUssdText = "";

            Console.Clear();
            Console.ForegroundColor = ConsoleColor.Yellow;
            Console.WriteLine(@"
 ┌──────────────────────────────────────────────┐
 │   📱 VIRTUAL FEATURE PHONE USSD SIMULATOR    │
 │   Dialing: *123#                             │
 │   Telco: Orange Liberia / Lonestar MTN       │
 └──────────────────────────────────────────────┘");
            Console.ResetColor();

            while (true)
            {
                var resp = await client.CallUssdAsync(sessionId, phone, currentUssdText);
                if (resp == null)
                {
                    Console.ForegroundColor = ConsoleColor.Red;
                    Console.WriteLine("\nUSSD Gateway Connection Failed.");
                    Console.ResetColor();
                    break;
                }

                Console.ForegroundColor = ConsoleColor.White;
                Console.WriteLine("\n┌──────────────────────────────────────────────┐");
                foreach (var line in resp.Message.Split('\n'))
                {
                    Console.WriteLine($"│ {line,-44} │");
                }
                Console.WriteLine("└──────────────────────────────────────────────┘");
                Console.ResetColor();

                if (!resp.ContinueSession)
                {
                    Console.ForegroundColor = ConsoleColor.Green;
                    Console.WriteLine("\nSession Terminated by Network (END).");
                    Console.ResetColor();
                    break;
                }

                Console.ForegroundColor = ConsoleColor.Cyan;
                Console.Write("Enter option (or 'q' to hang up): ");
                Console.ResetColor();
                var input = Console.ReadLine()?.Trim();

                if (string.IsNullOrEmpty(input) || input.ToLower() == "q")
                {
                    Console.WriteLine("Hanging up USSD call...");
                    break;
                }

                if (string.IsNullOrEmpty(currentUssdText))
                {
                    currentUssdText = input;
                }
                else
                {
                    currentUssdText += "*" + input;
                }
            }
        }

        PauseForUser();
    }
    else if (choice == "5")
    {
        // ==========================================
        // MODULE 5: VETTED CARI KNOWLEDGE BASE (RAG)
        // ==========================================
        Console.Clear();
        Console.ForegroundColor = ConsoleColor.Green;
        Console.WriteLine("\n[MODULE 5] VETTED RAG KNOWLEDGE BASE AUDIT (Rule ADV-01)");
        Console.WriteLine("Verify all agricultural chemical & cultural advice is strictly grounded in CARI guides");
        Console.WriteLine(new string('=', 75));
        Console.ResetColor();

        Console.Write("Filter by Crop (Cassava / Pepper / ALL): ");
        var crop = Console.ReadLine()?.Trim();
        var docs = await client.GetKnowledgeAsync(crop);

        Console.WriteLine($"\nFound {docs.Count} CARI Extension Guide(s):");
        Console.WriteLine(new string('-', 75));

        foreach (var d in docs)
        {
            Console.ForegroundColor = ConsoleColor.Yellow;
            Console.WriteLine($"\n[DOC: {d.DocId}] {d.ConditionName} ({d.Crop})");
            Console.ResetColor();
            Console.WriteLine($"  Approved By:    {d.ApprovedBy} · {d.SourceOrg}");
            Console.WriteLine($"  Symptoms:       {d.SymptomDescription}");
            Console.ForegroundColor = ConsoleColor.Cyan;
            Console.WriteLine($"  Cultural Mgmt:  {d.CulturalControl}");
            Console.ForegroundColor = ConsoleColor.Magenta;
            Console.WriteLine($"  Chemical Mgmt:  {d.ChemicalControl}");
            Console.ForegroundColor = ConsoleColor.Green;
            Console.WriteLine($"  Vetted SMS:     \"{d.VettedSmsTemplate}\" ({d.VettedSmsTemplate.Length}/160 chars)");
            Console.ResetColor();
            Console.WriteLine(new string('-', 75));
        }

        PauseForUser();
    }
    else if (choice == "6")
    {
        // ==========================================
        // MODULE 6: AI DIAGNOSTICS & SAFETY VALIDATOR
        // ==========================================
        Console.Clear();
        Console.ForegroundColor = ConsoleColor.Blue;
        Console.WriteLine("\n[MODULE 6] AI DIAGNOSTICS & SAFETY VALIDATOR (Rule SCAN-03)");
        Console.WriteLine("Demonstrate Confidence Bands (High/Med/Low) & Explicit Abstention on Unsupported Crops");
        Console.WriteLine(new string('=', 75));
        Console.ResetColor();

        Console.WriteLine("Select Crop Sample to Run Through Vision Engine:");
        Console.WriteLine("  1. Cassava Leaf (Supported - Healthy / Disease Test)");
        Console.WriteLine("  2. Pepper Leaf  (Supported - Anthracnose / Healthy Test)");
        Console.WriteLine("  3. Maize Leaf   (UNSUPPORTED - Test Rule SCAN-03 Abstention Guardrail)");
        Console.WriteLine("  4. Cocoa Leaf   (UNSUPPORTED - Test Rule SCAN-03 Abstention Guardrail)");
        Console.Write("\nSelect sample (1-4): ");

        var sOpt = Console.ReadLine()?.Trim();
        string testCrop = sOpt switch
        {
            "1" => "Cassava",
            "2" => "Pepper",
            "3" => "Maize",
            "4" => "Cocoa",
            _ => "Cassava"
        };

        Console.WriteLine($"\nSubmitting leaf scan for crop '{testCrop}' to /api/v1/diagnose...");
        var diag = await client.RunDiagnosticsAsync(testCrop);

        if (diag != null)
        {
            Console.ForegroundColor = ConsoleColor.White;
            Console.WriteLine("\nDIAGNOSTIC PIPELINE RESULT:");
            Console.WriteLine(new string('-', 70));
            Console.ResetColor();

            if (!diag.IsSupported)
            {
                Console.ForegroundColor = ConsoleColor.Red;
                Console.WriteLine($"✓ RULE SCAN-03 TRIGGERED: Crop '{diag.CropType}' is NOT in supported list!");
                Console.WriteLine($"  Status:         {diag.Status}");
                Console.WriteLine($"  Message:        {diag.Message}");
                Console.WriteLine($"  Safety Action:  Explicit warning returned to farmer instead of hallucinating.");
                Console.ResetColor();
            }
            else
            {
                Console.ForegroundColor = ConsoleColor.Green;
                Console.WriteLine($"✓ SUPPORTED CROP: {diag.CropType}");
                Console.ResetColor();
                Console.WriteLine($"  Case Number:    {diag.CaseNumber}");
                Console.WriteLine($"  AI Finding:     {diag.Diagnosis} (Severity: {diag.Severity})");
                Console.WriteLine($"  Confidence:     {diag.ConfidenceScore * 100:0}% (Band: {diag.ConfidenceBand})");
                Console.WriteLine($"  Vetted Doc:     {diag.KnowledgeDocId}");
                Console.ForegroundColor = ConsoleColor.Cyan;
                Console.WriteLine($"  Message:        {diag.Message}");
                Console.ResetColor();
            }
            Console.WriteLine(new string('-', 70));
        }
        else
        {
            Console.ForegroundColor = ConsoleColor.Red;
            Console.WriteLine("Failed to run diagnostics. Verify backend service.");
            Console.ResetColor();
        }

        PauseForUser();
    }
    else if (choice == "7")
    {
        // ==========================================
        // MODULE 7: CONFIGURE API TARGET
        // ==========================================
        Console.Clear();
        Console.ForegroundColor = ConsoleColor.Cyan;
        Console.WriteLine("\n[CONFIG] CONFIGURE API TARGET ENDPOINT");
        Console.WriteLine(new string('=', 50));
        Console.ResetColor();
        Console.WriteLine($"Current API Target: {client.BaseUrl}");
        Console.WriteLine("\nPresets:");
        Console.WriteLine("  1. Local Development (http://localhost:8000/api/v1)");
        Console.WriteLine("  2. Railway Production (https://plant-production.up.railway.app/api/v1)");
        Console.WriteLine("  3. Custom URL");
        Console.Write("\nChoice (1-3): ");

        var cfg = Console.ReadLine()?.Trim();
        if (cfg == "1")
        {
            currentApiUrl = "http://localhost:8000/api/v1";
        }
        else if (cfg == "2")
        {
            currentApiUrl = "https://plant-production.up.railway.app/api/v1";
        }
        else if (cfg == "3")
        {
            Console.Write("Enter Base API URL: ");
            var custom = Console.ReadLine()?.Trim();
            if (!string.IsNullOrEmpty(custom))
            {
                currentApiUrl = custom;
            }
        }
        client = new ApiClient(currentApiUrl);
        Console.ForegroundColor = ConsoleColor.Green;
        Console.WriteLine($"\n✓ Target updated to: {client.BaseUrl}");
        Console.ResetColor();
        PauseForUser();
    }
    else if (choice == "8")
    {
        Console.ForegroundColor = ConsoleColor.Green;
        Console.WriteLine("\nExiting Desktop Workstation. Goodbye, Gorpu & John!");
        Console.ResetColor();
        break;
    }
}
