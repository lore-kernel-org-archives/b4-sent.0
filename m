From: David Heidelberg <david@ixit.cz>
Subject: [PATCH RFC 0/8] media: camss: Add support for C-PHY configuration
 on Qualcomm platforms
Date: Sun, 09 Nov 2025 10:39:43 +0100
Message-Id: <20251109-qcom-cphy-v1-0-165f7e79b0e1@ixit.cz>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAF9hEGkC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1NDQwNL3cLk/Fzd5IKMSt2kJIvkpJREw2QzExMloPqCotS0zAqwWdFKQW7
 OSrG1tQCzqm6gYAAAAA==
X-Change-ID: 20251109-qcom-cphy-bb8cbda1c644
To: Robert Foss <rfoss@kernel.org>, Todor Tomov <todor.too@gmail.com>, 
 Bryan O'Donoghue <bryan.odonoghue@linaro.org>, 
 Vladimir Zapolskiy <vladimir.zapolskiy@linaro.org>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Luca Weiss <luca.weiss@fairphone.com>, Petr Hodina <phodina@protonmail.com>, 
 Casey Connolly <casey.connolly@linaro.org>, "Dr. Git" <drgitx@gmail.com>
Cc: Joel Selvaraj <foss@joelselvaraj.com>, linux-media@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>, 
 Sakari Ailus <sakari.ailus@linux.intel.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=2819; i=david@ixit.cz;
 h=from:subject:message-id; bh=1mafSDjzBgsMCZ7ArlDk0UuSa3iSLw6qNMUKGLRpjvw=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpEGFy2+CmwZYEuSn/R9jhfOrAc/Q8g4MAn54NH
 Jy0hZCQstqJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaRBhcgAKCRBgAj/E00kg
 ciHkD/9M7HjTM7Vr9eE8Z+80lQ5KK/JshPHF4fZsh/lgPbPqOcGyq+05W28Jnu+PKSsjp7Dn8MR
 b7wM4PyKskvy/iLrBVgMzY9xM2v6iIzrratp1gLfoDRWLmStSmMcDvWebgFz+ocWGnd9iX4PL5T
 Pe9hUCwlWNrEFAqHDj9WEZbsgI0/PKtVzRL1aDDBal/lobxzEfklLjtTNwhvIHPWVpfRSGjQlMM
 XJD9965Th9OqvMX6wfDv6c3zw21AFmxZ+rg6REX25nqGMIYomuTM6ZIJBGpO0JmINRc15WjgTgp
 que14JxgJ6C0cCdMoNYFIdJKFFUUjSOOWgfyqV9UPWJNzXas7RGMGwBJnimXSBuSa1jwsTuFUdB
 mfgfSTbVDzrMCZnVF08Oc+knH53pv/9r4EoGrObSDdpMVmV3HdD3Es8KzQfXKM0Sllo9Cwwr9R3
 QZZmKF4yqQwDUkcimMptVN339cktKgPVnASrWsYGf6vJ3lznXVUnE9l6afsIdMvITEaMpLbnf51
 ACtmAIiKdNqgyq2DdnzFzmL+YZkb0VhkddzxnyzG4xBivuurdNs6d7MHgGTZ2ub6lIzEBlWtGM+
 dEoP8CRHKy9d7UPCLs2GmSV3XtG3MYodFYBT+YNGSYv+W97VaObg8UHSjz/P7f576kjXhRHSrww
 ko1toCiSge6IXfg==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

# Short summary

This patch series extends the Qualcomm CAMSS (Camera Subsystem),
including CSID and CSIPHY components, to support C-PHY mode configuration.

# Background and motivation

Modern smartphone cameras increasingly rely on MIPI C-PHY rather than D-PHY,
thanks to its higher data throughput and signal efficiency. As a result,
many OEMs adopt C-PHY interfaces for main (rear) cameras on Qualcomm-based
devices.

Until now, mainline Linux lacked C-PHY configuration support for Qualcomm
chipsets, preventing bring-up of primary camera sensors on several
Snapdragon platforms. This series closes that gap.

 - Introduces C-PHY configuration support for the CAMSS driver stack,
   covering both CSID and CSIPHY blocks.
 - Successfully enables C-PHY operation on the Snapdragon 845 platform.
 - Tested on OnePlus 6 and 6T phones running mainline Linux,
   using the Sony IMX519 main camera sensor.
 - The new configuration allows other chipsets versionsto enable C-PHY by
   simply adding corresponding sensor driver support and csiphy
   initialization data, following the example set for sdm845.

With this patch series, mainline Linux gains working C-PHY support for
Snapdragon 845, paving the way for improved main camera functionality
across many Qualcomm-based devices. The groundwork also simplifies
future enablement efforts for additional SoCs and sensors.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
Casey Connolly (1):
      media: qcom: camss: csiphy-3ph: Add Gen2 v1.1 MIPI CSI-2 CPHY init

David Heidelberg (6):
      media: qcom: camss: csiphy: Introduce C-PHY
      media: qcom: camss: csiphy-3ph: Use odd bits for configuring C-PHY lanes
      media: qcom: camss: Prepare CSID for C-PHY support
      media: qcom: camss: csiphy-3ph: Use sdm845 C-PHY configuration sequence
      media: qcom: camss: Account for C-PHY when calculating link frequency
      media: qcom: camss: Remove D-PHY-only endpoint restriction

Petr Hodina (1):
      media: qcom: camss: Initialize lanes after lane configuration is available

 .../media/platform/qcom/camss/camss-csid-gen2.c    |   1 +
 drivers/media/platform/qcom/camss/camss-csid.c     |   3 +-
 drivers/media/platform/qcom/camss/camss-csid.h     |   1 +
 .../platform/qcom/camss/camss-csiphy-3ph-1-0.c     | 165 ++++++++++++++++-----
 drivers/media/platform/qcom/camss/camss-csiphy.c   |   6 +-
 drivers/media/platform/qcom/camss/camss-csiphy.h   |   2 +
 drivers/media/platform/qcom/camss/camss.c          |  24 ++-
 drivers/media/platform/qcom/camss/camss.h          |   2 +-
 8 files changed, 146 insertions(+), 58 deletions(-)
---
base-commit: 9c0826a5d9aa4d52206dd89976858457a2a8a7ed
change-id: 20251109-qcom-cphy-bb8cbda1c644

Best regards,
-- 
David Heidelberg <david@ixit.cz>

