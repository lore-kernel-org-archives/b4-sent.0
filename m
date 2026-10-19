From: Rinat Muhamedgaliev <rinat.muhamedgaliev@gmail.com>
Subject: [PATCH v8] bq27xxx: support interchangeable OnePlus 6/6T fuel
 gauges
Date: Mon, 19 Oct 2026 22:08:15 +0300
Message-Id: <20261019-master-v8-0-2517e41c8992@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/23OwVLDIBAG4FfpcBZlKYHgyffoeIBlk+CYxIGYq
 dPJuwvttGrH4w/77b8nlilFyux5d2KJ1pjjPJXQPuwYDm7qicdQMpNCamGl4aPLCyXug3BdsNp
 q6lgZ/kjUxeN50eH1kvOnfyNcqq4T3mXiPrkJh/o0p9jH6emyrv4PMS9z+jpfsqq651raXktXx
 YGLRqLZE4LR5qUfXXx/xHlktXRtbgwE/LCGCy48gVYKMAS4Z/o3szemC0Pl9xqkNRLonpn/mSn
 MQYeqbYNF8+fIbdu+AXijMnRzAQAA
X-Change-ID: 20260927-master-bd0afd9696ef
To: linux-pm@vger.kernel.org
Cc: pali@kernel.org, sre@kernel.org, afd@ti.com, 
 konrad.dybcio@oss.qualcomm.com, david@ixit.cz, krzk@kernel.org, 
 linux-arm-msm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Rinat Muhamedgaliev <rinat.muhamedgaliev@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792436896; l=1896;
 i=rinat.muhamedgaliev@gmail.com; s=default; h=from:subject:message-id;
 bh=CD8dFs9AlJtwpKfUnsvq0wg/Q2D+U0BfFeHkOTnO1ao=;
 b=0PD716yO6KNtHjWDCzFcCPrl+bGIv771UFfFBdxZ+zubSRm7gaQ+5S4MRostIbW2Fl+A5BbGC
 EEJiTt3pvN9D+iaKVJCoQ4xxhmVmd2VXUMumhnPc8HUNN1UFBrXxeoK
X-Developer-Key: i=rinat.muhamedgaliev@gmail.com; a=ed25519;
 pk=qkYQO8LRlRErWiLzlpK8jHbRIxv8+7v06+ytcxX8mec=
X-Endpoint-Received: by B4 Relay for rinat.muhamedgaliev@gmail.com/default with auth_id=1072
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

OnePlus 6 and 6T battery packs can contain either a bq27411 or a bq27541
fuel gauge. The two chips require different register maps.

The DeviceType check now lives in the bus-neutral battery core, where it
uses the existing register-map and control-register helpers. For bq27411
and bq27541, it compares the type selected by the compatible with the
reported type and chooses the detected profile.

Tested on a OnePlus 6T with DeviceType 0x0541 (bq27541): 4.338 V, 100%
capacity, 27.8 C, and Full/Good status. Testing on DeviceType 0x0421
(bq27411) hardware would be appreciated.

Changes in v8:
- Move DeviceType detection to the bus-neutral battery core.
- Use the existing register map and control-command definitions.
- Link to v7: https://patch.msgid.link/20261019-master-v7-0-a1fc488d9c77@gmail.com

Changes in v7:
- Determine the expected DeviceType through an extensible chip switch.
- Mark the probe-time list for extension with DeviceType-capable fuel gauges.
- Link to v6: https://patch.msgid.link/20261019-master-v6-0-c4b36129721e@gmail.com

Changes in v6:
- Compare the detected model with the compatible-selected model.
- Support both BQ27411-to-BQ27541 and BQ27541-to-BQ27411 detection.

Changes in v5:
- Report detected and expected DeviceType values instead of hard-coding chip names.
- Describe an unknown DeviceType as unrecognized.

Changes in v4:
- Drop the generic compatible and binding update.
- Keep the established OnePlus DTS unchanged.

---
Rinat Muhamedgaliev (1):
      power: supply: bq27xxx: detect bq27541 behind bq27411 compatible

 drivers/power/supply/bq27xxx_battery.c | 61 ++++++++++++++++++++++++++++++++++
 1 file changed, 61 insertions(+)
---
base-commit: 830b3c68c1fb1e9176028d02ef86f3cf76aa2476
change-id: 20260927-master-bd0afd9696ef

Best regards,
--  
Rinat Muhamedgaliev <rinat.muhamedgaliev@gmail.com>

