From: Wayne Ho <wayneho219@gmail.com>
Date: Thu, 01 Oct 2026 14:45:11 +0800
Subject: [PATCH 1/2] Documentation: ABI: leds: inverted is specific to the
 backlight trigger
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261001-docs-leds-abi-trigger-attrs-v1-1-54f0529bf0f6@gmail.com>
References: <20261001-docs-leds-abi-trigger-attrs-v1-0-54f0529bf0f6@gmail.com>
In-Reply-To: <20261001-docs-leds-abi-trigger-attrs-v1-0-54f0529bf0f6@gmail.com>
To: Pavel Machek <pavel@kernel.org>, Lee Jones <lee@kernel.org>
Cc: linux-leds@vger.kernel.org, linux-kernel@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790837130; l=1162;
 i=wayneho219@gmail.com; s=20261001; h=from:subject:message-id;
 bh=1kSwJWvbUgMk5BRB5AL/9PD/agaA7eFnk07FgPmlgzs=;
 b=4Gnq8XKnv0dE9+gXX1PvOlz68AZIlNAO/k8ZgC8MOag6pRcjb0AlMRUxifGXbfOK7EZH9mF7i
 qzIk5sF6U2fDml+Xjmqr9MRHovpHFTYFVJTFYgYacenFskq7/Y8pv4H
X-Developer-Key: i=wayneho219@gmail.com; a=ed25519;
 pk=j25LRSikYRlv0PpovZSgSrCQwsy7WDzIYum/mydUa3A=
X-Endpoint-Received: by B4 Relay for wayneho219@gmail.com/20261001 with auth_id=1093
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The description of the inverted attribute says it is specific to the
gpio and backlight triggers, but the gpio trigger no longer creates it;
it only provides desired_brightness. Only the backlight trigger creates
the inverted attribute today.

Drop the reference to the gpio trigger.

Signed-off-by: Wayne Ho <wayneho219@gmail.com>
---
 Documentation/ABI/testing/sysfs-class-led | 5 ++---
 1 file changed, 2 insertions(+), 3 deletions(-)

diff --git a/Documentation/ABI/testing/sysfs-class-led b/Documentation/ABI/testing/sysfs-class-led
index d4c918cc..c72cb1e0 100644
--- a/Documentation/ABI/testing/sysfs-class-led
+++ b/Documentation/ABI/testing/sysfs-class-led
@@ -84,6 +84,5 @@ KernelVersion:	2.6.38
 Contact:	Richard Purdie <rpurdie@rpsys.net>
 Description:
 		Invert the LED on/off state. This parameter is specific to
-		gpio and backlight triggers. In case of the backlight trigger,
-		it is useful when driving a LED which is intended to indicate
-		a device in a standby like state.
+		the backlight trigger. It is useful when driving a LED which
+		is intended to indicate a device in a standby like state.

-- 
Git-155)

