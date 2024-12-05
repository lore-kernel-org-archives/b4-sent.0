From: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
Subject: [PATCH 0/2] cpufreq: qcom: Clock provider fixes
Date: Thu, 05 Dec 2024 22:20:27 +0530
Message-Id: <20241205-qcom-cpufreq-clk-fix-v1-0-de46c82e0fe5@linaro.org>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIANPZUWcC/x2MSQqAMBDAviJzdqAWN/yKeKjtVAe3LiiC+HeLx
 wSSByIFpghd9kCgiyMfe4Iiz0DPap8I2SQGKWRZSFGh18eG2p02kEe9Lmj5RlULO1pjmrEtIaU
 uUNL/th/e9wNM/J98ZgAAAA==
To: "Rafael J. Wysocki" <rafael@kernel.org>, 
 Viresh Kumar <viresh.kumar@linaro.org>, 
 Xiu Jianfeng <xiujianfeng@huawei.com>
Cc: linux-arm-msm@vger.kernel.org, linux-pm@vger.kernel.org, 
 linux-clk@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Johan Hovold <johan+linaro@kernel.org>, Stephen Boyd <sboyd@kernel.org>, 
 Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=openpgp-sha256; l=1286;
 i=manivannan.sadhasivam@linaro.org; h=from:subject:message-id;
 bh=eRPnmWYSQhSAftRfnhYQ4HXep5ZbnD5fgGUew/TmFlk=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBnUdnlN4Zr7BQSl7WojL2S8I1Hp6T7Kvw8mk7HT
 09RtBftfCWJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCZ1HZ5QAKCRBVnxHm/pHO
 9aA/CACJ/g/EEk/bHPAxG0CiFqR6jDDHBhVCpzWWDbQv+5L+cQDLw5GmgiiZ/sYzcHS3+pXS09p
 cDdXyDqQjZaN+up+agDGQc9EPzSuaE6I1PWoNJ/eyeR3UjB5/x7eBBAwmJdVTo4chS7AdYUv18V
 ghz7NBoCQvqFXKmEf2r3RbHn/D0lI9kTpxfs7SepHAqzifg8bHYq1gw+XWbYazjgzM8OBGAKb1c
 CUnWjysjDfvL/ilLiJgONqPH00Wzh6JBeZ5jtIovE+uwW0DTHSTEBbwegIWKIUMsx3Vyxh8bR4F
 NtA+Eqgc0IEKyNYa+NAYPmAstOnOjVPV91gWFt7/jw5OuL+A
X-Developer-Key: i=manivannan.sadhasivam@linaro.org; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@linaro.org/default with auth_id=185
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi,

This series has a couple of fixes for the Qcom CPUFreq clock provider.
Patch 1 fixes an issue where incorrect rate might be reported if LMh IRQ is not
available for a platform (issue identified based on code inspection). Patch 2
fixes a regression reported for v6.13-rc1 [1]. The regression was triggered by
commit 25f1c96a0e84 ("clk: Fix invalid execution of clk_set_rate"), which fixed
the behavior of the clk_set_rate() API. Even though the commit got reverted now,
patch 2 fixes the issue in the clock provider code.

This series is tested on Qcom RB5 development board.

[1] https://lore.kernel.org/all/20241202100621.29209-1-johan+linaro@kernel.org

Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
---
Manivannan Sadhasivam (2):
      cpufreq: qcom: Fix qcom_cpufreq_hw_recalc_rate() to query LUT if LMh IRQ is not available
      cpufreq: qcom: Implement clk_ops::determine_rate() for qcom_cpufreq* clocks

 drivers/cpufreq/qcom-cpufreq-hw.c | 34 ++++++++++++++++++++++++----------
 1 file changed, 24 insertions(+), 10 deletions(-)
---
base-commit: 40384c840ea1944d7c5a392e8975ed088ecf0b37
change-id: 20241205-qcom-cpufreq-clk-fix-a60fbfdd7b84

Best regards,
-- 
Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>

