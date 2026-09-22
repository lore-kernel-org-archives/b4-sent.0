From: Jaidev Shastri <jaidevshastri@vt.edu>
Date: Mon, 21 Sep 2026 21:11:26 -0400
Subject: [PATCH] cpufreq: qcom-hw: order driver state before registration
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260921-mb-qcom-cpufreq-v1-1-b5943c3fce18@vt.edu>
X-B4-Tracking: v=1; b=H4sIAL3VsWoC/yXMwQ6CMBAE0F8he3YN1KrRXyEe2nVXakKBrRATw
 r/b4vFNZmaFxBo4wb1aQXkJKQwxozlUQJ2LL8bwzAZTm0t9Mw32HicaeqRxFuUJrZHm7MSLswJ
 5NSpL+O6P7ePvNPs306fclIZ3idGri9SVaOdyPZ5QycK2/QC1nYZZkwAAAA==
X-Change-ID: 20260921-mb-qcom-cpufreq-42f15afbfa4f
To: "Rafael J. Wysocki" <rafael@kernel.org>, 
 Viresh Kumar <viresh.kumar@linaro.org>
Cc: linux-arm-msm@vger.kernel.org, linux-pm@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Jaidev Shastri <jaidevshastri@vt.edu>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790039488; l=1920;
 i=jaidevshastri@vt.edu; s=20260921; h=from:subject:message-id;
 bh=/khXpPvYG7xlCLQJOIORkk6TQr/7EtBeJQkfKyRMxTE=;
 b=0BGrPAhrCFaS38T+KMlDx9jG3b+MEp/WJCI3qdQpw3GQISguImziZ6zV8jJ3lFlr4NoMTXatR
 pC3M8znConwCgCbPXwTPaBwcJFpWDZiqRKCjILZ04zCpSzkntSgJKlN
X-Developer-Key: i=jaidevshastri@vt.edu; a=ed25519;
 pk=J7+xYJRlTPds+pv5hbqFFRqGCpDeJDzmZT1ggRwj7/0=
X-Endpoint-Received: by B4 Relay for jaidevshastri@vt.edu/20260921 with auth_id=1044
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

qcom_cpufreq_hw_driver_probe() stores xo_rate, cpu_hw_rate,
qcom_cpufreq.soc_data and the per-domain qcom_cpufreq.data[] array with
plain stores and then calls cpufreq_register_driver(). The cpufreq core
invokes qcom_cpufreq_hw_cpu_init() for every policy, on other CPUs, and
that function reads all of them with plain loads.

Order the stores before the registration with smp_wmb() and add the
matching smp_rmb() in qcom_cpufreq_hw_cpu_init().

Found with MBCheck, a static herd7-based memory consistency checker.

Signed-off-by: Jaidev Shastri <jaidevshastri@vt.edu>
---
 drivers/cpufreq/qcom-cpufreq-hw.c | 9 +++++++++
 1 file changed, 9 insertions(+)

diff --git a/drivers/cpufreq/qcom-cpufreq-hw.c b/drivers/cpufreq/qcom-cpufreq-hw.c
index 874ff3fb9..62cc1f403 100644
--- a/drivers/cpufreq/qcom-cpufreq-hw.c
+++ b/drivers/cpufreq/qcom-cpufreq-hw.c
@@ -554,6 +554,8 @@ static int qcom_cpufreq_hw_cpu_init(struct cpufreq_policy *policy)
 		return ret;
 
 	index = args.args[0];
+	/* Pairs with the smp_wmb() before cpufreq_register_driver() in probe. */
+	smp_rmb();
 	data = &qcom_cpufreq.data[index];
 
 	/* HW should be in enabled state to proceed */
@@ -738,6 +740,13 @@ static int qcom_cpufreq_hw_driver_probe(struct platform_device *pdev)
 		return ret;
 	}
 
+	/*
+	 * qcom_cpufreq_hw_cpu_init() runs on other CPUs through the cpufreq
+	 * core once the driver is registered and reads xo_rate, cpu_hw_rate,
+	 * qcom_cpufreq.soc_data and qcom_cpufreq.data[]. Order those stores
+	 * before the registration. Pairs with the smp_rmb() in cpu_init.
+	 */
+	smp_wmb();
 	ret = cpufreq_register_driver(&cpufreq_qcom_hw_driver);
 	if (ret)
 		dev_err(dev, "CPUFreq HW driver failed to register\n");

---
base-commit: 93f51579e7df248780214094418f205253383cc5
change-id: 20260921-mb-qcom-cpufreq-42f15afbfa4f

Best regards,
--  
Jaidev Shastri <jaidevshastri@vt.edu>

