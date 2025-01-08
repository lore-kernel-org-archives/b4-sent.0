From: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
Subject: [PATCH 0/2] bus: mhi: host: pci_generic: Couple of recovery fixes
Date: Wed, 08 Jan 2025 19:09:26 +0530
Message-Id: <20250108-mhi_recovery_fix-v1-0-a0a00a17da46@linaro.org>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAA6AfmcC/x2MQQqAIBAAvxJ7TtCisr4SEWFr7iGNFaQI/550n
 IGZFyIyYYSpeoExUaTgC6i6AuM2f6CgvTA0sumkklqcjlZGExLys1q6xaZtO6he21EZKNnFWPS
 /nJecP/3Spx5iAAAA
To: mhi@lists.linux.dev, Loic Poulain <loic.poulain@linaro.org>
Cc: Johan Hovold <johan@kernel.org>, linux-arm-msm@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>, 
 stable@vger.kernel.org
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=openpgp-sha256; l=865;
 i=manivannan.sadhasivam@linaro.org; h=from:subject:message-id;
 bh=4r45CBYevJCU4R4Er9l1ZcNs5c3/H5PCLL4UP6si+F8=;
 b=owGbwMvMwMUYOl/w2b+J574ynlZLYkivaxCM+1ymbOnoteVZ+B2xnzGu/UEGFasDQh3SJ6Usf
 MTjeTCpk9GYhYGRi0FWTJElfamzVqPH6RtLItSnwwxiZQKZwsDFKQATcS9l/6ctxylhqf7W8uu8
 RDFdWQ6+PNvt1UydlflLNrP8ZDxqqX9kuUFN1XFrndCgrflNBhx/TDaLGnQ1HPvNVv/TJSs8Y7n
 thYMxolZL1LessPhsbWujY69tKnm9ccEuj5pLbctPb1daYrj/9ibB13dlbk0w3iZeX/ZqWsGd6R
 5Xck0XrFvtUOfNem9SZEwBZ8TGiibHL6eWHPM7eLpLiaNKtPhysols64aG+uqbF43VuN9ZeTpxd
 fXxHpNLMXp2utHrQVUrv2Cx2dYy00Km9qmZaRuUIjnPTvMPmvrvz0btloOHBHYZP5Hz4I3YvNpT
 TUB9pTTjghcvb6bNL1sZmBnhtbh4IYtblcAX6dev+a4BAA==
X-Developer-Key: i=manivannan.sadhasivam@linaro.org; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@linaro.org/default with auth_id=185
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi,

This series fixes a couple of issues reported by Johan in [1]. First one fixes
a deadlock that happens during shutdown and suspend. Second one fixes the
driver's PM behavior.

[1] https://lore.kernel.org/mhi/Z1me8iaK7cwgjL92@hovoldconsulting.com

Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
---
Manivannan Sadhasivam (2):
      bus: mhi: host: pci_generic: Use pci_try_reset_function() to avoid deadlock
      bus: mhi: host: pci_generic: Recover the device synchronously from mhi_pci_runtime_resume()

 drivers/bus/mhi/host/pci_generic.c | 29 +++++++++++++++++------------
 1 file changed, 17 insertions(+), 12 deletions(-)
---
base-commit: fc033cf25e612e840e545f8d5ad2edd6ba613ed5
change-id: 20250108-mhi_recovery_fix-a8f37168f91c

Best regards,
-- 
Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>

