From: Yedaya Katsman <yedaya.ka@gmail.com>
Subject: [PATCH v4 0/3] Support FT3518 touchscreen in xiaomi-laurel
Date: Tue, 20 Jan 2026 23:40:53 +0200
Message-Id: <20260120-touchscreen-patches-v4-0-30145da9d6d3@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/33NTQ6DIBCG4as0rEsDI/jTVe/RdAE4CkkVA9a0M
 d696Mo0psv3S+aZmUQMDiO5nmYScHLR+T6FOJ+Isapvkbo6NQEGOeM8o6N/GRtNQOzpoEZjMVK
 NGiTkupaNJulyCNi496beH6mti6MPn+3JxNf1vzdxyqjirJJFk0Fdl7e2U+55Mb4jqzfB3hDHB
 iRDAJdNJUyptPo1sr1RHhtZMrjJVQGVkajF3liW5QsMz2LjPgEAAA==
X-Change-ID: 20260113-touchscreen-patches-beb2526bd5fb
To: =?utf-8?q?Kamil_Go=C5=82da?= <kamil.golda@protonmail.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: linux-input@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 Yedaya Katsman <yedaya.ka@gmail.com>, SzczurekYT <szczurek@szczurek.yt>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1768945262; l=1661;
 i=yedaya.ka@gmail.com; s=20260113; h=from:subject:message-id;
 bh=YJzJJUi++2uUYfkEQ8T6yu3Qy4wq058C1WeL4Qj82gQ=;
 b=P9IIClJs67VvxEvmdkAc9XXIk6TJyBBK8SZjxJggcpfStBtgXVdTjJnTHYtdHSVJW9WT3q0pW
 mlUti4myNM7ATfiWvqf6d4FeyHa16sOcvwJ5P3UbJIDACWfqGVu/s8s
X-Developer-Key: i=yedaya.ka@gmail.com; a=ed25519;
 pk=CgNmxD3tYSws5dZfpmJfc6re/bV/f47veVijddHLytk=
X-Endpoint-Received: by B4 Relay for yedaya.ka@gmail.com/20260113 with auth_id=601
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Adds support for the touchscreen in the Xiaomi Mi A3 (xiaomi-laurel)
 smartphone, FocalTech FT3518

Original tree was here:
 Link: https://gitlab.postmarketos.org/SzczurekYT/linux/-/commits/laurel

Signed-off-by: Yedaya Katsman <yedaya.ka@gmail.com>
---
Changes in v4:
- Follow dts coding style for pinctrl nodes
- Don't refrence touchscreen "release" gpio config
- Link to v3: https://lore.kernel.org/r/20260118-touchscreen-patches-v3-0-1c6a729c5eb4@gmail.com

Changes in v3:
- Rename regulator node and reorder nodes
- Add gpio pin configuration for pmx_ts_* in sm6125, and reference in the
  touchscreen configuration as pinctrl-*. Doesn't have configuration for
  the gpio 83 pin since it isn't documented downstream.
- Link to v2: https://lore.kernel.org/r/20260114-touchscreen-patches-v2-0-4215f94c8aba@gmail.com

Changes in v2:
- Fixed name and email in signoffs
- Link to v1: https://lore.kernel.org/r/20260113-touchscreen-patches-v1-0-a10957f32dd8@gmail.com

---
Yedaya Katsman (3):
      dt-bindings: input: touchscreen: edt-ft5x06: Add FocalTech FT3518
      drivers: input: touchscreen: edt-ft5x06: Add FocalTech FT3518
      arm64: dts: qcom: sm6125-xiaomi-laurel-sprout: Add Focaltech FT3518 touchscreen

 .../bindings/input/touchscreen/edt-ft5x06.yaml     |  1 +
 .../boot/dts/qcom/sm6125-xiaomi-laurel-sprout.dts  | 65 ++++++++++++++++++++++
 drivers/input/touchscreen/edt-ft5x06.c             |  6 ++
 3 files changed, 72 insertions(+)
---
base-commit: b71e635feefc852405b14620a7fc58c4c80c0f73
change-id: 20260113-touchscreen-patches-beb2526bd5fb

Best regards,
-- 
Yedaya Katsman <yedaya.ka@gmail.com>

