From: =?utf-8?q?J=C3=A9r=C3=B4me_de_Bretagne?= <jerome.debretagne@gmail.com>
Date: Thu, 18 Dec 2025 23:22:08 +0100
Subject: [PATCH v4 2/6] dt-bindings: wireless: ieee80211: Add
 disable-rfkill property
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20251218-surface-sp11-for-next-v4-2-7bcf83c1504a@gmail.com>
References: <20251218-surface-sp11-for-next-v4-0-7bcf83c1504a@gmail.com>
In-Reply-To: <20251218-surface-sp11-for-next-v4-0-7bcf83c1504a@gmail.com>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Johannes Berg <johannes@sipsolutions.net>, 
 Lorenzo Bianconi <lorenzo@kernel.org>, 
 Maximilian Luz <luzmaximilian@gmail.com>, Hans de Goede <hansg@kernel.org>, 
 =?utf-8?q?Ilpo_J=C3=A4rvinen?= <ilpo.jarvinen@linux.intel.com>, 
 Jeff Johnson <jjohnson@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-wireless@vger.kernel.org, 
 platform-driver-x86@vger.kernel.org, ath12k@lists.infradead.org, 
 Dale Whinham <daleyo@gmail.com>, 
 =?utf-8?q?J=C3=A9r=C3=B4me_de_Bretagne?= <jerome.debretagne@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1766096532; l=1478;
 i=jerome.debretagne@gmail.com; s=20251217; h=from:subject:message-id;
 bh=B9SXON9447NJlyUwxvW/LOflPUSy2K70Poc9F3eFNw8=;
 b=6xy4ZN2Bjipgy1VaHvOCUKuf+yH/Mwv9z9bRIvBwuHX4VgyxuYeIgU+DmyJ8ZLuMxdFi2O8Zg
 FBtzIHdvDsiCQLpPSCJJ2htZ+OBPAS780TQyhpkZ5MAspDpo8dsPINC
X-Developer-Key: i=jerome.debretagne@gmail.com; a=ed25519;
 pk=DcPD9n3oDMsPkt+12tU96swmGb5H86cxt+yiEVcUEGk=
X-Endpoint-Received: by B4 Relay for jerome.debretagne@gmail.com/20251217 with auth_id=580
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

For some devices, Wi-Fi is entirely hard blocked by default making
the Wi-Fi radio unusable, except if rfkill is disabled as expected
on those models.

Commit c6a7c0b09d5f ("wifi: ath12k: Add Support for enabling or
disabling specific features based on ACPI bitflag") added a way to
support features set via ACPI, including the DISABLE_RFKILL bit.

Add a disable-rfkill property to expose the DISABLE_RFKILL bit
equivalent for devices described by a Devicetree instead of ACPI.

Tested-by: Dale Whinham <daleyo@gmail.com>
Signed-off-by: Jérôme de Bretagne <jerome.debretagne@gmail.com>
---
 Documentation/devicetree/bindings/net/wireless/ieee80211.yaml | 6 ++++++
 1 file changed, 6 insertions(+)

diff --git a/Documentation/devicetree/bindings/net/wireless/ieee80211.yaml b/Documentation/devicetree/bindings/net/wireless/ieee80211.yaml
index d89f7a3f88a71d45d6f4ab2ae909eae09cbcaf9a..c10a4675640be947cd0b5eaec2c7ff367fd93945 100644
--- a/Documentation/devicetree/bindings/net/wireless/ieee80211.yaml
+++ b/Documentation/devicetree/bindings/net/wireless/ieee80211.yaml
@@ -29,6 +29,12 @@ properties:
       different 5 GHz subbands. Using them incorrectly could not work or
       decrease performance noticeably
 
+  disable-rfkill:
+    type: boolean
+    description:
+      Disable rfkill for some devices on which Wi-Fi would be entirely hard
+      blocked by default otherwise
+
 additionalProperties: true
 
 examples:

-- 
2.47.3

