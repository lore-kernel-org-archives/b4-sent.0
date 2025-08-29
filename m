From: Cryolitia PukNgae <cryolitia@uniontech.com>
Date: Fri, 29 Aug 2025 16:46:06 +0800
Subject: [PATCH] ALSA: docs: Add documents for recently changes in
 snd-usb-audio
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250829-sound-doc-v1-1-e0110452b03d@uniontech.com>
X-B4-Tracking: v=1; b=H4sIAM1osWgC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1MDCyNL3eL80rwU3ZT8ZF1z42SzVFMTEwvLFEMloPqCotS0zAqwWdGxtbU
 AYedTW1sAAAA=
X-Change-ID: 20250829-sound-doc-73c6e54489d1
To: Jaroslav Kysela <perex@perex.cz>, Takashi Iwai <tiwai@suse.com>, 
 Jonathan Corbet <corbet@lwn.net>
Cc: linux-sound@vger.kernel.org, linux-doc@vger.kernel.org, 
 linux-kernel@vger.kernel.org, niecheng1@uniontech.com, 
 zhanjun@uniontech.com, Cryolitia PukNgae <cryolitia@uniontech.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1756457187; l=3763;
 i=cryolitia@uniontech.com; s=20250730; h=from:subject:message-id;
 bh=HE89odsIwYI1Vul0J0CIerepfkejArZ/qTv9Q4oEXbY=;
 b=K4pQlW5283gHmgF0tuapReYbIHgrysYjpS0ltdEVRBVl5YcdIkLPZNJiNbKub9gScdwYiODmH
 koJvJicRJ6jAAjgm5wFOaskFcTntv3F86uVw9M/5r+XCm+6sbPDOBHQ
X-Developer-Key: i=cryolitia@uniontech.com; a=ed25519;
 pk=tZ+U+kQkT45GRGewbMSB4VPmvpD+KkHC/Wv3rMOn/PU=
X-Endpoint-Received: by B4 Relay for cryolitia@uniontech.com/20250730 with auth_id=474
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Changed:
  - ignore_ctl_error
  - lowlatency
  - skip_validation
  - quirk_flags[19:24]

Signed-off-by: Cryolitia PukNgae <cryolitia@uniontech.com>
---
 Documentation/sound/alsa-configuration.rst | 29 +++++++++++++++++++++++++----
 1 file changed, 25 insertions(+), 4 deletions(-)

diff --git a/Documentation/sound/alsa-configuration.rst b/Documentation/sound/alsa-configuration.rst
index a45174d165ebdeadd89de5f556483465c5f6e808..77fd70ac12975a271600ebd542672a3afb443d39 100644
--- a/Documentation/sound/alsa-configuration.rst
+++ b/Documentation/sound/alsa-configuration.rst
@@ -2253,8 +2253,15 @@ device_setup
     Default: 0x0000 
 ignore_ctl_error
     Ignore any USB-controller regarding mixer interface (default: no)
+    ``ignore_ctl_error=1`` may help when you get an error at accessing
+    the mixer element such as URB error -22.  This happens on some
+    buggy USB device or the controller.  This workaround corresponds to
+    the ``quirk_flags`` bit 14, too.
 autoclock
     Enable auto-clock selection for UAC2 devices (default: yes)
+lowlatency
+    Enable low latency playback mode (default: yes).
+    Could disable it to switch back to the old mode if face a regression.
 quirk_alias
     Quirk alias list, pass strings like ``0123abcd:5678beef``, which
     applies the existing quirk for the device 5678:beef to a new
@@ -2284,6 +2291,11 @@ delayed_register
     The driver prints a message like "Found post-registration device
     assignment: 1234abcd:04" for such a device, so that user can
     notice the need.
+skip_validation
+    Skip unit descriptor validation (default: no).
+    The option is used to ignores the validation errors with the hexdump
+    of the unit descriptor instead of a driver probe error, so that we
+    can check its details.
 quirk_flags
     Contains the bit flags for various device specific workarounds.
     Applied to the corresponding card index.
@@ -2307,6 +2319,16 @@ quirk_flags
         * bit 16: Set up the interface at first like UAC1
         * bit 17: Apply the generic implicit feedback sync mode
         * bit 18: Don't apply implicit feedback sync mode
+        * bit 19: Don't closed interface during setting sample rate
+        * bit 20: Force an interface reset whenever stopping & restarting
+          a stream
+        * bit 21: Do not set PCM rate (frequency) when only one rate is
+          available for the given endpoint.
+        * bit 22: Set the fixed resolution 16 for Mic Capture Volume
+        * bit 23: Set the fixed resolution 384 for Mic Capture Volume
+        * bit 24: Set minimum volume control value as mute for devices
+          where the lowest playback value represents muted state instead
+          of minimum audible volume
 
 This module supports multiple devices, autoprobe and hotplugging.
 
@@ -2314,10 +2336,9 @@ NB: ``nrpacks`` parameter can be modified dynamically via sysfs.
 Don't put the value over 20.  Changing via sysfs has no sanity
 check.
 
-NB: ``ignore_ctl_error=1`` may help when you get an error at accessing
-the mixer element such as URB error -22.  This happens on some
-buggy USB device or the controller.  This workaround corresponds to
-the ``quirk_flags`` bit 14, too.
+NB: ``ignore_ctl_error=1`` just provides A quick way to work around the
+issues.  If you have a buggy device that requires these quirks, please
+report it to the upstream.
 
 NB: ``quirk_alias`` option is provided only for testing / development.
 If you want to have a proper support, contact to upstream for

---
base-commit: 15be520ab00cfc9c59fa1623de6757f61ab42d8a
change-id: 20250829-sound-doc-73c6e54489d1

Best regards,
-- 
Cryolitia PukNgae <cryolitia@uniontech.com>

