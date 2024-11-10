From: Maud Spierings <maud_spierings@hotmail.com>
Date: Sun, 10 Nov 2024 19:05:02 +0100
Subject: [PATCH] Input: docs: Fix the input_event struct documentation
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241110-fix_input_doc-v1-1-745d5f908e61@hotmail.com>
X-B4-Tracking: v=1; b=H4sIAM31MGcC/x2MQQqAIBAAvxJ7TnCjiPpKRKS71l4stCIQ/550H
 JiZBJGDcISxShD4kSiHL4B1BXZf/cZKqDA0umkRUSsn7yL+vK+FDquQ2LjeWBpsB6U5Axfh/01
 zzh8lKx+AXwAAAA==
X-Change-ID: 20241110-fix_input_doc-1debf7bcd9c5
To: Dmitry Torokhov <dmitry.torokhov@gmail.com>, 
 Jonathan Corbet <corbet@lwn.net>
Cc: linux-input@vger.kernel.org, linux-doc@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Maud Spierings <maud_spierings@hotmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1731261906; l=989;
 i=maud_spierings@hotmail.com; s=20241110; h=from:subject:message-id;
 bh=C55UbquVRgOMqi6UfZZBpAe/1aOdlwpfJfKcF6CPsNI=;
 b=CQvLWKLBbf1pXbv7y9zWnHjF4IH0ndv5lI+R3SdakQNXVtyCWCDjpsKy/M+buAs3eNTNh8HRi
 jFMbz304H9hBtsU6dyMqVreEMVUDWvmjwCXITwtX48QfdHNJqdGlzUg
X-Developer-Key: i=maud_spierings@hotmail.com; a=ed25519;
 pk=CeFKVnZvRfX2QjB1DpdiAe2N+MEjwLEB9Yhx/OAcxRc=
X-Endpoint-Received: by B4 Relay for maud_spierings@hotmail.com/20241110 with auth_id=273
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Fix the datatype of the value field of the input_event struct which is
signed instead of unsigned.
See include/uapi/linux/input.h

Signed-off-by: Maud Spierings <maud_spierings@hotmail.com>
---
 Documentation/input/input.rst | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/Documentation/input/input.rst b/Documentation/input/input.rst
index 2c67fa904adcf902cebf8e7137c0a1609d879a50..d9a6de87d02de5301500b392191ab67e7db431ed 100644
--- a/Documentation/input/input.rst
+++ b/Documentation/input/input.rst
@@ -264,7 +264,7 @@ events on a read. Their layout is::
 	    struct timeval time;
 	    unsigned short type;
 	    unsigned short code;
-	    unsigned int value;
+	    int value;
     };
 
 ``time`` is the timestamp, it returns the time at which the event happened.

---
base-commit: de2f378f2b771b39594c04695feee86476743a69
change-id: 20241110-fix_input_doc-1debf7bcd9c5

Best regards,
-- 
Maud Spierings <maud_spierings@hotmail.com>

