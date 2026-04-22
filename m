From: Aaron Kling <webgeek1234@gmail.com>
Subject: [PATCH v6 0/2] drm/panel: Add panel driver for ChipWealth CH13726A
 based panels
Date: Wed, 22 Apr 2026 02:43:23 -0500
Message-Id: <20260422-ch13726a-v6-0-03680d6673ff@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/2XPTW7DIBAF4KtYrEs1DAbGXvUeVRf8DAlSEzd2a
 jWKcvcSp5KtdDmIb96bq5h4LDyJvrmKkecyleFYB/vSiLj3xx3LkuosENACIsi4V9qh9dJ00Vp
 HyehEon7/GjmXn2XV+8djHvn0XTeeH48i+IllHA6Hcu6bwGzZa4gtOSJWpFvS0GXqFCfyOWTnA
 H0U2yZ98+ihnPSXozzFiYwBqWwEF6xOjLafjbjH78t0HsbLctislvy/G3C9YVYSJBtQydUKYPz
 b7uDL52stuSyZcYW6hq4QK0TyvrUhJpvgGeoNRL2B+p6IFGzuXGb6B9sVtkAb2FbYhaB8Fyhr7
 J6h2UBUG2gqzC7b3GYNDGYLb7fbL1cZfL8DAgAA
X-Change-ID: 20260220-ch13726a-59c6678d53d8
To: Neil Armstrong <neil.armstrong@linaro.org>, 
 Jessica Zhang <jesszhan0024@gmail.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: dri-devel@lists.freedesktop.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Teguh Sobirin <teguh@sobir.in>, 
 Aaron Kling <webgeek1234@gmail.com>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1776843820; l=2679;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=IZr7RTAdxhkJ/lgF3S2u0E922vN1YnMMh25lXatpibc=;
 b=uFXcjC0ouNG/Zv4BGaGP4EHRfyB4e8yCSJ3ew9FYHuH8qsQ68qUGLJjbkNdi6LHlsHEs6YB4f
 PNXUefb/1LgAnBUdltvpY3tLDdQcvjeTv29CrkWOYhhREE5ThrLsy0N
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This driver is based on the one by Teguh Sobirin [0], cut down to only
support the AYN Thor bottom panel.

Due to [1], the AYN vendor description patch has been folded into the
AYN QCS8550 dt series. Which means this series now depends on said
series and it must be picked up before this.

[0] https://github.com/AYNTechnologies/linux/commit/d0ff75b09e66023c5f88992706dee4601aa7a437
[1] https://lore.kernel.org/linux-arm-msm/c7fb3f89-6574-4761-9ef2-2fdf6d4801b5@kernel.org

Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
Changes in v6:
- Add trailers from v4
- Link to v5: https://lore.kernel.org/r/20260421-ch13726a-v5-0-f7f6f4f30e05@gmail.com

Changes in v5:
- Don't duplicate prepared tracking
- Use devm_regulator_bulk_get_const() instead of setting names in probe
- Use devm_drm_panel_alloc() instead of drm_panel_init()
- Link to v4: https://lore.kernel.org/r/20260408-ch13726a-v4-0-9bb1a9b8f329@gmail.com

Changes in v4:
- Add fallback compatible to bindings doc in patch 1
- Link to v3: https://lore.kernel.org/r/20260323-ch13726a-v3-0-e28b6f97fe80@gmail.com

Changes in v3:
- Reword patch 1 commit message for clarity
- Order properties properly in patch 1
- Track vendor description dependency series change
- Link to v2: https://lore.kernel.org/r/20260317-ch13726a-v2-0-28aa46bcd6d0@gmail.com

Changes in v2:
- Add Neil Armstrong to binding maintainer list
- Add 120hz mode, which required a minor restructure of the driver
- Link to v1: https://lore.kernel.org/r/20260222-ch13726a-v1-0-e501d78e105a@gmail.com

---
Aaron Kling (1):
      dt-bindings: display: panel: Add ChipWealth CH13726A AMOLED driver

Teguh Sobirin (1):
      drm/panel: Add panel driver for ChipWealth CH13726A based panels

 .../display/panel/chipwealth,ch13726a.yaml         |  67 +++++
 drivers/gpu/drm/panel/Kconfig                      |  11 +
 drivers/gpu/drm/panel/Makefile                     |   1 +
 drivers/gpu/drm/panel/panel-chipwealth-ch13726a.c  | 333 +++++++++++++++++++++
 4 files changed, 412 insertions(+)
---
base-commit: bee6ea30c48788e18348309f891ed8afbf7702ac
change-id: 20260220-ch13726a-59c6678d53d8
prerequisite-change-id: 20260217-ayn-qcs8550-16c07b63de26:v5
prerequisite-patch-id: 2b010637c46f5ea0e19a2fa87cc5ccb19bfd9204
prerequisite-patch-id: d0c633dc17f0aba726a8e8d21fee52b944bf67ff
prerequisite-patch-id: 76ac126273870a96f05e1bd87f4f31bdc3746440
prerequisite-patch-id: 76b61799dba520fc7fa3ff39b044e24103337af3
prerequisite-patch-id: 3844bef2eda3cf59031b1d131eb6ba9295629bb4
prerequisite-patch-id: 3331648bc6f4ac3bb156f0525aa1ede92bfc57f1

Best regards,
-- 
Aaron Kling <webgeek1234@gmail.com>

