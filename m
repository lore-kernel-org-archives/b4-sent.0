From: Yang Xiwen <forbidden405@outlook.com>
Date: Sat, 31 May 2025 21:10:02 +0800
Subject: [PATCH 1/2] arm: armv7: restore section to .text after saved_args
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250531-pie_blob_fix-v1-1-7b4a37987dbc@outlook.com>
References: <20250531-pie_blob_fix-v1-0-7b4a37987dbc@outlook.com>
In-Reply-To: <20250531-pie_blob_fix-v1-0-7b4a37987dbc@outlook.com>
To: Tom Rini <trini@konsulko.com>, 
 Ilias Apalodimas <ilias.apalodimas@linaro.org>, 
 Raymond Mao <raymond.mao@linaro.org>, 
 Rayagonda Kokatanur <rayagonda.kokatanur@broadcom.com>
Cc: u-boot@lists.denx.de, Yang Xiwen <forbidden405@outlook.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1748697019; l=787;
 i=forbidden405@outlook.com; s=20230724; h=from:subject:message-id;
 bh=jpS30FhFq7BpJW0prlSwZ9UeWyw3m/sRYRuGCarZRng=;
 b=6g3n8LEXd5CF2RoHf/TZY2u8HdHXE0/xdLGXiVGwfCb+q7qz1Fn22/1hkLOTqAwYI73JrcA0a
 BL0AfPouGZnBeK67jql2ZnRkW9JqPdb4aEGHiPx1+PLwpva8auBD6jD
X-Developer-Key: i=forbidden405@outlook.com; a=ed25519;
 pk=qOD5jhp891/Xzc+H/PZ8LWVSWE3O/XCQnAg+5vdU2IU=
X-Endpoint-Received: by B4 Relay for forbidden405@outlook.com/20230724 with auth_id=67
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

when CONFIG_BLOBLIST is enabled, the section is switched to .data but is
not switched back to .text. It makes all the code below placed in .data
section, also breaks CONFIG_POSITION_INDEPENDENT.

Fix it by adding `.section .text` to switch the section back to .text.

Fixes: 5103e69344d6 ("arm: armv7: save boot arguments")
Signed-off-by: Yang Xiwen <forbidden405@outlook.com>
---
 arch/arm/cpu/armv7/start.S | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/arch/arm/cpu/armv7/start.S b/arch/arm/cpu/armv7/start.S
index 959251957de4..833486817f84 100644
--- a/arch/arm/cpu/armv7/start.S
+++ b/arch/arm/cpu/armv7/start.S
@@ -182,6 +182,8 @@ saved_args:
 	.word 0
 	.endr
 END(saved_args)
+
+	.section .text
 #endif
 
 #ifdef CONFIG_ARMV7_LPAE

-- 
2.43.0

