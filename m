From: Rinat Muhamedgaliev <rinat.muhamedgaliev@gmail.com>
Subject: [PATCH v6] bq27xxx: support interchangeable OnePlus 6/6T fuel
 gauges
Date: Mon, 19 Oct 2026 00:15:53 +0300
Message-Id: <20261019-master-v6-0-c4b36129721e@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/02OzQ6CMBCEX8X0bLXFUsST72E89GeBNVJMi42G8
 O5SCOpxduebmYEE8AiBnDYD8RAxYOcmIbcbYhrlaqBoJ00ylklWZgVtVejBU22ZqmwpSwkVmcw
 PDxW+5qDLddHhqW9g+kQnh1YBqPbKmSadOo81uv0Sl/4Nhr7z73lJFClnLT2upVFQTlmemeIAh
 heyONetwvvOdC1JpTH/YpzxH5ZTRpkGLoXgxlr+j43j+AFKnswsBQEAAA==
X-Change-ID: 20260927-master-bd0afd9696ef
To: linux-pm@vger.kernel.org
Cc: pali@kernel.org, sre@kernel.org, afd@ti.com, 
 konrad.dybcio@oss.qualcomm.com, david@ixit.cz, krzk@kernel.org, 
 linux-arm-msm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Rinat Muhamedgaliev <rinat.muhamedgaliev@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792358153; l=1717;
 i=rinat.muhamedgaliev@gmail.com; s=default; h=from:subject:message-id;
 bh=SHrvdvbxCKtRIdlifie6qEUHDb0k2UQIfxEZWKPC62g=;
 b=iBOg7Z4TxpAdOSuJt3HRuvXtiybtz8yJk/g8EgW9pH067j+70MW//oHEMpOPbET61hTGpcari
 fupeyxW2YSBDXaSd2NhcrcOHELpDkXKTUhgjVPUNG7ihFQDA1DvrXhp
X-Developer-Key: i=rinat.muhamedgaliev@gmail.com; a=ed25519;
 pk=qkYQO8LRlRErWiLzlpK8jHbRIxv8+7v06+ytcxX8mec=
X-Endpoint-Received: by B4 Relay for rinat.muhamedgaliev@gmail.com/default with auth_id=1072
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

OnePlus 6 and 6T replacement battery packs can contain either a bq27411 or a
bq27541 fuel gauge. The latter requires a different register map and produces
invalid battery readings when interpreted as a bq27411.

The I2C driver reads DeviceType while probing either of those compatible
devices and selects the matching profile.

The bq27541 path was tested on a OnePlus 6T with DeviceType 0x0541. It
reported 4.338 V, 100% capacity, 27.8 C, and Full/Good battery status.
Testing on an OnePlus 6 or 6T whose fuel gauge reports DeviceType 0x0421
(bq27411) would be appreciated.

Changes in v6:
- Compare the detected model with the compatible-selected model.
- Support both BQ27411-to-BQ27541 and BQ27541-to-BQ27411 detection.
- Document the pair of models checked at probe time.
- Link to v5: https://patch.msgid.link/20261018-master-v5-0-0be16441cdd1@gmail.com

Changes in v5:
- Report detected and expected DeviceType values instead of hard-coding chip names.
- Describe an unknown DeviceType as unrecognized.
- Link to v4: https://patch.msgid.link/20260928-master-v4-1-052c73ec1767@gmail.com

Changes in v4:
- Drop the generic compatible and binding update.
- Keep the established OnePlus DTS unchanged.
- Detect bq27541 from DeviceType in the bq27411 probe path.
- Send as a new thread.

---
Rinat Muhamedgaliev (1):
      power: supply: bq27xxx: detect bq27541 behind bq27411 compatible

 drivers/power/supply/bq27xxx_battery_i2c.c | 57 ++++++++++++++++++++++++++++++
 1 file changed, 57 insertions(+)
---
base-commit: 830b3c68c1fb1e9176028d02ef86f3cf76aa2476
change-id: 20260927-master-bd0afd9696ef

Best regards,
--  
Rinat Muhamedgaliev <rinat.muhamedgaliev@gmail.com>

