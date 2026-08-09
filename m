From: David Heidelberg <david@ixit.cz>
Subject: [PATCH 0/2] Pixel 3 display fixes
Date: Sun, 09 Aug 2026 02:04:28 +0200
Message-Id: <20260809-fix-blueline-panel-v1-0-e7f3a6beb1fa@ixit.cz>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMywqDMBSE4VeRs/ZAzMJLX0W6SOLEnhJSSVQK4
 rs31uUHM/9BGUmQ6VEdlLBLlk8saOqK3MvEGSxTMWmlW9Wrgb182YYNQSJ4MRGBjde2c0PbeT1
 ROS4JZfWPjs/bebNvuPUq0Xn+AKUKhdN2AAAA
X-Change-ID: 20260809-fix-blueline-panel-af2b7c967f2d
To: Sumit Semwal <sumit.semwal@linaro.org>, 
 Casey Connolly <casey.connolly@linaro.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Jessica Zhang <jesszhan0024@gmail.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Dmitry Baryshkov <lumag@kernel.org>, 
 Marijn Suijten <marijn.suijten@somainline.org>, 
 Vinod Koul <vkoul@kernel.org>
Cc: dri-devel@lists.freedesktop.org, linux-kernel@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=891; i=david@ixit.cz;
 h=from:subject:message-id; bh=ZtdBQ/ahumDHXcx5VpIi2GsmmsHcwZY7yFycaqOz58I=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqd8QPDB/IjJhsxFS9IR4ByO8d0VkQeuDXzY1A0
 iZHIvQpRTCJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCanfEDwAKCRBgAj/E00kg
 ckKMEADBrBr79RIGllAVa62yrqdAKJBtyIKF0r3XbXaLyyLI8ok2Vw/AZeaaOy+/dVeoRHRAUwZ
 fJ9Pbp4qrAETzLQ890JapXp0+b+Lc1UFwTnpxl8HT2Nev6DIpp3x6SmmouJeKMJEBiluNNMCJ6K
 OkYuXWP/EUJpx2vyrZNNncVn6lrBiRl1/u+Sq5+Q+bNXWn58orvXk/STg5vtaLl2WGM0Ew4uRii
 d1tNA4NftJzeIpn8L/DfSzH5cM8LPk+eZgyny6BRUolrhijwjwpS2GPHg9DxfPNe/bEnlY0QlWz
 NTLtlh40nO3Dt45jKYC5+EEwhRoWkAXjkPTUch4dvtw0aYx9eOwU5nohV9Yo6lQq96JL36Hoyko
 d54ksSkkcKWfFD4Yz1mWAvcyi/YKqd7zt61FT1nPIUYvkJsb4nfgTNK53Svd9c2OwPkka4ilSBn
 Agr8K9I7aic9LvvfuLWkpxg/2/YRg9s3lC1h7fJFjCUbbsJQQsgMkZhT2Jz8fZBUyw+GKhk4197
 XznQbX4ZPGDlTMucnErG9rjzcZ6bH34a/EGBLhYgHotOu9hcSdrsi9wVCj+9Ediyf6dvN7qq6Vr
 0M2pKgxz2ZD1lq4hq7ZDsV/arfLSKScO4/TocVD4xjkleRKgMYFGluVN5zXpIPVKCvIYRlCbaMX
 3aiPHQ1I90pmlEQ==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Fix panel not recovering after unprepare and backlight intensity.

I extensively reproduced the vendor bootloader sequence, but after the
boot isn't possible to do the full initialization of the display (at
least on Pixel 3, and panel can't be found anywhere else).

The downstream, due to having attached touchscreen reusing same
supplies, never turns the panel off. Let's do the same.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
David Heidelberg (2):
      drm/panel: lg-sw43408: do not assert reset across unprepare
      drm/panel: lg-sw43408: use the full DCS brightness range

 drivers/gpu/drm/panel/panel-lg-sw43408.c | 14 ++++++++++----
 1 file changed, 10 insertions(+), 4 deletions(-)
---
base-commit: 95d6a9ccef99117115e41e9adb271243bd5e985b
change-id: 20260809-fix-blueline-panel-af2b7c967f2d

Best regards,
--  
David Heidelberg <david@ixit.cz>

