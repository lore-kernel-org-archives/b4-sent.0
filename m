From: Ciro Pedrini <ciro.pedrini@gmail.com>
Date: Tue, 10 Nov 2026 20:29:47 +0000
Subject: [PATCH v2 1/2] platform/x86: ideapad-laptop: Ignore keyboard
 backlight hotkeys
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261110-legion-lighting-rfc-v2-1-845726afb71c@gmail.com>
References: <20261110-legion-lighting-rfc-v2-0-845726afb71c@gmail.com>
In-Reply-To: <20261110-legion-lighting-rfc-v2-0-845726afb71c@gmail.com>
To: Mark Pearson <mpearson-lenovo@squebb.ca>, 
 "Derek J. Clark" <derekjohn.clark@gmail.com>, Rong Zhang <i@rong.moe>, 
 Ike Panhc <ikepanhc@gmail.com>, Hans de Goede <hansg@kernel.org>, 
 =?utf-8?q?Ilpo_J=C3=A4rvinen?= <ilpo.jarvinen@linux.intel.com>, 
 Jiri Kosina <jikos@kernel.org>, Benjamin Tissoires <bentiss@kernel.org>
Cc: Werner Sembach <wse@tuxedocomputers.com>, 
 Aaron Erhardt <aer@tuxedocomputers.com>, 
 platform-driver-x86@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-input@vger.kernel.org, Ciro Pedrini <ciro.pedrini@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794342675; l=1858;
 i=ciro.pedrini@gmail.com; h=from:subject:message-id;
 bh=7AFCuFhOORimBVaTct9i1sflefhIhf8+Hwo+UNCUras=;
 b=8psn2DxjjhsetxBvgzeTC4Jlsdo/RpQvtlFN0LLWfRg7WQR4okgyYI7GsAGxAs3Gs31DcU+7K
 kmTEIaljSx+D5Ihim4mT+uTBn4VVr8GuUwnx/73uS/hd4T8BUwFWPZE
X-Developer-Key: i=ciro.pedrini@gmail.com; a=ed25519;
 pk=TOSFlPBon1xBHfTrhODxatabgwEJdgKEzG3jMoMQcbc=
X-Endpoint-Received: by B4 Relay for ciro.pedrini@gmail.com/default with auth_id=1468
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On the Legion Pro 7 16IAX10H, Fn+Space (backlight effect), Fn+Up and
Fn+Down (backlight brightness) emit WMI fn-key events 0x21, 0x1a and
0x19, which the keymap does not cover, so they reach userspace as
KEY_UNKNOWN. The keyboard's USB controller handles these keys itself: it
switches the effect or changes the brightness, and reports the new level
on its own HID interface. Ignore the three events, as is already done for
FnLock and Esc, rather than mapping them to KEY_KBDILLUM*, which would
make userspace change the brightness a second time.

Tested on the 16IAX10H with 7.2: with the change, evtest shows no events
for the three keys, and the keyboard still switches the effect and the
brightness.

Signed-off-by: Ciro Pedrini <ciro.pedrini@gmail.com>
---
Prepared with Claude Code (Claude Opus 5.5) from evtest on the laptop's
"Ideapad extra buttons" device; I reviewed and tested it.
---
 drivers/platform/x86/lenovo/ideapad-laptop.c | 4 ++++
 1 file changed, 4 insertions(+)

diff --git a/drivers/platform/x86/lenovo/ideapad-laptop.c b/drivers/platform/x86/lenovo/ideapad-laptop.c
index 91a8d11c79c5..8b6c08b21c8d 100644
--- a/drivers/platform/x86/lenovo/ideapad-laptop.c
+++ b/drivers/platform/x86/lenovo/ideapad-laptop.c
@@ -1336,6 +1336,10 @@ static const struct key_entry ideapad_keymap[] = {
 	{ KE_IGNORE,	0x02 | IDEAPAD_WMI_KEY },
 	/* Esc (handled by the firmware) */
 	{ KE_IGNORE,	0x03 | IDEAPAD_WMI_KEY },
+	/* Keyboard backlight down, up and effect (handled by the keyboard) */
+	{ KE_IGNORE,	0x19 | IDEAPAD_WMI_KEY },
+	{ KE_IGNORE,	0x1a | IDEAPAD_WMI_KEY },
+	{ KE_IGNORE,	0x21 | IDEAPAD_WMI_KEY },
 	/* Customizable Lenovo Hotkey ("star" with 'S' inside) */
 	{ KE_KEY,	0x01 | IDEAPAD_WMI_KEY, { KEY_FAVORITES } },
 	{ KE_KEY,	0x04 | IDEAPAD_WMI_KEY, { KEY_SELECTIVE_SCREENSHOT } },

-- 
2.56.0

