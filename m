From: Aaron Kling <webgeek1234@gmail.com>
Date: Thu, 18 Dec 2025 15:39:52 -0600
Subject: [PATCH] cpufreq: Add Tegra186 and Tegra194 to cpufreq-dt-platdev
 blocklist
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251218-cpufreq-dt-block-tegra186-194-v1-1-24adeea10b86@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x3MwQqCQBAG4FeROTfQLCXWq0QHnf3XhkJtVkMQ3
 92l43f5NspwQ6Z7tZHjZ9nGoUBOFemrHXqwxWIK53CVIA3rtCTHl+PM3WfUN8/ovZWmZrldWFN
 INbSDRFA5Jkey9f8/nvt+AGgpY25vAAAA
X-Change-ID: 20251218-cpufreq-dt-block-tegra186-194-cf2f6ecbe1de
To: "Rafael J. Wysocki" <rafael@kernel.org>, 
 Viresh Kumar <viresh.kumar@linaro.org>
Cc: linux-pm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Aaron Kling <webgeek1234@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1766094000; l=1011;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=NeuYHwaGhtf7Xwzd+4B3Gb3sX3e9KS9/TfvzfQbvhwc=;
 b=xciAxoY3GJgvChXqtKjoSv7DCCIujX80mlun25nM6obSqyP+9dllSHp3qd4jEszgD9RjVdIDV
 5Rp7P3GQqtxAUhPKN5faJvvwo1MwoYTiBkqkL/lmDjmqiEkkpdy46a+
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

These have platform specific drivers.

Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
 drivers/cpufreq/cpufreq-dt-platdev.c | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/drivers/cpufreq/cpufreq-dt-platdev.c b/drivers/cpufreq/cpufreq-dt-platdev.c
index b06a43143d23c6365e1e0b26d4299ef4b0c3482f..1708179b2610bca6035d10f0f4766eee6f73912e 100644
--- a/drivers/cpufreq/cpufreq-dt-platdev.c
+++ b/drivers/cpufreq/cpufreq-dt-platdev.c
@@ -147,6 +147,8 @@ static const struct of_device_id blocklist[] __initconst = {
 	{ .compatible = "nvidia,tegra30", },
 	{ .compatible = "nvidia,tegra114", },
 	{ .compatible = "nvidia,tegra124", },
+	{ .compatible = "nvidia,tegra186", },
+	{ .compatible = "nvidia,tegra194", },
 	{ .compatible = "nvidia,tegra210", },
 	{ .compatible = "nvidia,tegra234", },
 

---
base-commit: 1058ca9db0edaedcb16480cc74b78ed06f0d1f54
change-id: 20251218-cpufreq-dt-block-tegra186-194-cf2f6ecbe1de

Best regards,
-- 
Aaron Kling <webgeek1234@gmail.com>

