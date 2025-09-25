From: Cryolitia PukNgae <cryolitia@uniontech.com>
Date: Thu, 25 Sep 2025 17:25:19 +0800
Subject: [PATCH v5 4/4] ALSA: doc: add docs about improved quirk_flags in
 snd-usb-audio
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250925-sound-v5-4-2593586ff350@uniontech.com>
References: <20250925-sound-v5-0-2593586ff350@uniontech.com>
In-Reply-To: <20250925-sound-v5-0-2593586ff350@uniontech.com>
To: Jaroslav Kysela <perex@perex.cz>, Takashi Iwai <tiwai@suse.com>, 
 Jonathan Corbet <corbet@lwn.net>
Cc: Mingcong Bai <jeffbai@aosc.io>, Kexy Biscuit <kexybiscuit@aosc.io>, 
 Nie Cheng <niecheng1@uniontech.com>, Zhan Jun <zhanjun@uniontech.com>, 
 Feng Yuan <fengyuan@uniontech.com>, qaqland <anguoli@uniontech.com>, 
 kernel@uniontech.com, linux-sound@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-doc@vger.kernel.org, 
 Cryolitia PukNgae <cryolitia@uniontech.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1758792317; l=6701;
 i=cryolitia@uniontech.com; s=20250730; h=from:subject:message-id;
 bh=D3poYh0GYU+tFf7qnpPKUesjmRl5ytfmzzsTuIWMHmQ=;
 b=Jf+f4ibh9/Lt5l5mLXKCcsRSqBjapHFreV4PC6YPgtBrtubTli4o6CUwIujEGcYdwWctQRNW6
 xOVRtRl0LeoAB+0Y46GpnpCDC4KZGL2pXCvVyGD8mk0+Nv6yThbY6Ed
X-Developer-Key: i=cryolitia@uniontech.com; a=ed25519;
 pk=tZ+U+kQkT45GRGewbMSB4VPmvpD+KkHC/Wv3rMOn/PU=
X-Endpoint-Received: by B4 Relay for cryolitia@uniontech.com/20250730 with auth_id=474
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Just briefly described about the option.

Signed-off-by: Cryolitia PukNgae <cryolitia@uniontech.com>
---
 Documentation/sound/alsa-configuration.rst | 108 ++++++++++++++++++++---------
 1 file changed, 75 insertions(+), 33 deletions(-)

diff --git a/Documentation/sound/alsa-configuration.rst b/Documentation/sound/alsa-configuration.rst
index a2fb8ed251dd0294e7a62209ca15d5c32c6adfae..0a4eaa7d66ddd05e7c7378596a351bb6ea17f9ba 100644
--- a/Documentation/sound/alsa-configuration.rst
+++ b/Documentation/sound/alsa-configuration.rst
@@ -2297,39 +2297,81 @@ skip_validation
     of the unit descriptor instead of a driver probe error, so that we
     can check its details.
 quirk_flags
-    Contains the bit flags for various device specific workarounds.
-    Applied to the corresponding card index.
-
-        * bit 0: Skip reading sample rate for devices
-        * bit 1: Create Media Controller API entries
-        * bit 2: Allow alignment on audio sub-slot at transfer
-        * bit 3: Add length specifier to transfers
-        * bit 4: Start playback stream at first in implement feedback mode
-        * bit 5: Skip clock selector setup
-        * bit 6: Ignore errors from clock source search
-        * bit 7: Indicates ITF-USB DSD based DACs
-        * bit 8: Add a delay of 20ms at each control message handling
-        * bit 9: Add a delay of 1-2ms at each control message handling
-        * bit 10: Add a delay of 5-6ms at each control message handling
-        * bit 11: Add a delay of 50ms at each interface setup
-        * bit 12: Perform sample rate validations at probe
-        * bit 13: Disable runtime PM autosuspend
-        * bit 14: Ignore errors for mixer access
-        * bit 15: Support generic DSD raw U32_BE format
-        * bit 16: Set up the interface at first like UAC1
-        * bit 17: Apply the generic implicit feedback sync mode
-        * bit 18: Don't apply implicit feedback sync mode
-        * bit 19: Don't closed interface during setting sample rate
-        * bit 20: Force an interface reset whenever stopping & restarting
-          a stream
-        * bit 21: Do not set PCM rate (frequency) when only one rate is
-          available for the given endpoint.
-        * bit 22: Set the fixed resolution 16 for Mic Capture Volume
-        * bit 23: Set the fixed resolution 384 for Mic Capture Volume
-        * bit 24: Set minimum volume control value as mute for devices
-          where the lowest playback value represents muted state instead
-          of minimum audible volume
-        * bit 25: Be similar to bit 24 but for capture streams
+    The option provides a refined and flexible control for applying quirk
+    flags.  It allows to specify the quirk flags for each device, and can
+    be modified dynamically via sysfs.
+    The old usage accepts an array of integers, each of which applies quirk
+    flags on the device in the order of probing.
+    E.g., ``quirk_flags=0x01,0x02`` applies get_sample_rate to the first
+    device, and share_media_device to the second device.
+    The new usage accepts a string in the format of
+    ``VID1:PID1:FLAGS1;VID2:PID2:FLAGS2;...``, where ``VIDx`` and ``PIDx``
+    specify the device, and ``FLAGSx`` specify the flags to be applied.
+    ``VIDx`` and ``PIDx`` are 4-digit hexadecimal numbers, and can be
+    specified as ``*`` to match any value.  ``FLAGSx`` can be a set of
+    flags given by name, separated by ``|``, or a hexadecimal number
+    representing the bit flags.  The available flag names are listed below.
+    An exclamation mark can be prefixed to a flag name to negate the flag.
+    For example, ``1234:abcd:mixer_playback_min_mute|!ignore_ctl_error;*:*:0x01;``
+    applies the ``mixer_playback_min_mute`` flag and clears the
+    ``ignore_ctl_error`` flag for the device 1234:abcd, and applies the
+    ``skip_sample_rate`` flag for all devices.
+
+        * bit 0: ``get_sample_rate``
+          Skip reading sample rate for devices
+        * bit 1: ``share_media_device``
+          Create Media Controller API entries
+        * bit 2: ``align_transfer``
+          Allow alignment on audio sub-slot at transfer
+        * bit 3: ``tx_length``
+          Add length specifier to transfers
+        * bit 4: ``playback_first``
+          Start playback stream at first in implement feedback mode
+        * bit 5: ``skip_clock_selector``
+          Skip clock selector setup
+        * bit 6: ``ignore_clock_source``
+          Ignore errors from clock source search
+        * bit 7: ``itf_usb_dsd_dac``
+          Indicates ITF-USB DSD-based DACs
+        * bit 8: ``ctl_msg_delay``
+          Add a delay of 20ms at each control message handling
+        * bit 9: ``ctl_msg_delay_1m``
+          Add a delay of 1-2ms at each control message handling
+        * bit 10: ``ctl_msg_delay_5m``
+          Add a delay of 5-6ms at each control message handling
+        * bit 11: ``iface_delay``
+          Add a delay of 50ms at each interface setup
+        * bit 12: ``validate_rates``
+          Perform sample rate validations at probe
+        * bit 13: ``disable_autosuspend``
+          Disable runtime PM autosuspend
+        * bit 14: ``ignore_ctl_error``
+          Ignore errors for mixer access
+        * bit 15: ``dsd_raw``
+          Support generic DSD raw U32_BE format
+        * bit 16: ``set_iface_first``
+          Set up the interface at first like UAC1
+        * bit 17: ``generic_implicit_fb``
+          Apply the generic implicit feedback sync mode
+        * bit 18: ``skip_implicit_fb``
+          Don't apply implicit feedback sync mode
+        * bit 19: ``iface_skip_close``
+          Don't close interface during setting sample rate
+        * bit 20: ``force_iface_reset``
+          Force an interface reset whenever stopping & restarting a stream
+        * bit 21: ``fixed_rate``
+          Do not set PCM rate (frequency) when only one rate is available
+          for the given endpoint
+        * bit 22: ``mic_res_16``
+          Set the fixed resolution 16 for Mic Capture Volume
+        * bit 23: ``mic_res_384``
+          Set the fixed resolution 384 for Mic Capture Volume
+        * bit 24: ``mixer_playback_min_mute``
+          Set minimum volume control value as mute for devices where the
+          lowest playback value represents muted state instead of minimum
+          audible volume
+        * bit 25: ``mixer_capture_min_mute``
+          Similar to bit 24 but for capture streams
 
 This module supports multiple devices, autoprobe and hotplugging.
 

-- 
2.51.0

