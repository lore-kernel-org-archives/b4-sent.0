From: "Pawel Zalewski (The Capable Hub)" <pzalewski@thegoodpenguin.co.uk>
Date: Tue, 04 Aug 2026 12:17:45 +0100
Subject: [PATCH] cache: hisi_soc_hha: use named initializers for
 acpi_device_id
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260804-cache-v1-1-a1491610bb01@thegoodpenguin.co.uk>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDCwNj3eTE5IxUXVPTNItUU4s08xRLEyWg2oKi1LTMCrA50bG1tQBvu8u
 +VwAAAA==
X-Change-ID: 20260803-cache-55f8e58f7d94
To: Yushan Wang <wangyushan12@huawei.com>, Conor Dooley <conor@kernel.org>, 
 Jonathan Cameron <jic23@kernel.org>
Cc: linux-kernel@vger.kernel.org, 
 "Pawel Zalewski (The Capable Hub)" <pzalewski@thegoodpenguin.co.uk>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785842267; l=985;
 i=pzalewski@thegoodpenguin.co.uk; s=20260803; h=from:subject:message-id;
 bh=NNsr2MNssAZSSxsLLDuvsyDSR5zfBIk/8ajvuv3yvHg=;
 b=gs7bBGr8d8b04pX04ZfyzhGOHHZdtxGhNcPMKXvdTZRVJxdE+XQ//YEo89ZnSmXr7bbOz9Q10
 VmWiUz5jgjdAwFjF5XsTkUMzyih3v/vNLfLDOpC8W9rFn1jA0SVgvEK
X-Developer-Key: i=pzalewski@thegoodpenguin.co.uk; a=ed25519;
 pk=W3zk1cb/wRnj6pNGbl3/2Zf3GmPA6IBpNHpDPyJ05k8=
X-Endpoint-Received: by B4 Relay for pzalewski@thegoodpenguin.co.uk/20260803 with auth_id=913
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Use a named initializer for the acpi_device_id fields which
makes the code more readable and consistent with how lists
are initialized in the rest of the kernel code base.

Signed-off-by: Pawel Zalewski (The Capable Hub) <pzalewski@thegoodpenguin.co.uk>
---
 drivers/cache/hisi_soc_hha.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/cache/hisi_soc_hha.c b/drivers/cache/hisi_soc_hha.c
index 756c43398515..f0f6c0354108 100644
--- a/drivers/cache/hisi_soc_hha.c
+++ b/drivers/cache/hisi_soc_hha.c
@@ -170,7 +170,7 @@ static void hisi_soc_hha_remove(struct platform_device *pdev)
 }
 
 static const struct acpi_device_id hisi_soc_hha_ids[] = {
-	{ "HISI0511", },
+	{ .id = "HISI0511" },
 	{ }
 };
 MODULE_DEVICE_TABLE(acpi, hisi_soc_hha_ids);

---
base-commit: 075b74841bd0065a3bda3440873c747938e69b68
change-id: 20260803-cache-55f8e58f7d94

Best regards,
--  
Pawel Zalewski (The Capable Hub) <pzalewski@thegoodpenguin.co.uk>

