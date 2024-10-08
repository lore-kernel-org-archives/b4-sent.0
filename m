From: Renjiang Han <quic_renjiang@quicinc.com>
Subject: [PATCH 0/2] media: venus: enable venus support on qcs615
Date: Tue, 08 Oct 2024 16:46:33 +0530
Message-Id: <20241008-add_qcs615_video-v1-0-436ce07bfc63@quicinc.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAJIUBWcC/x3MTQqAIBBA4avIrBM0U6KrRIQ5U82mH4UIxLsnL
 b/FexkSRaYEg8gQ6eHE51GhGwFh98dGkrEaWtV2WqleesT5DslpOz+MdErUhpRbnAlkoWZXpJX
 ffzlOpXy8HfYoYgAAAA==
X-Change-ID: 20241008-add_qcs615_video-d13e06b63ce5
To: Vikash Garodia <quic_vgarodia@quicinc.com>
Cc: kernel@quicinc.com, Renjiang Han <quic_renjiang@quicinc.com>, 
 linux-arm-msm@vger.kernel.org
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1728386222; l=837;
 i=quic_renjiang@quicinc.com; s=20241001; h=from:subject:message-id;
 bh=SriKfHfhoKdNS3/P6FDcBxmjpvDM1p0JnqL9IBCCw0Y=;
 b=H9WCnPW5vLCUv4vXCtd3MGtznp73rC5phpIg+6N/Idwxqs51T1ekpZwvG85hcWxOcFWYM9bhw
 b2FTg1F9IIFCM2fnjuFuj3pKAwu9vvHOvRUhJTjbkNtXnYTNV9QE6U1
X-Developer-Key: i=quic_renjiang@quicinc.com; a=ed25519;
 pk=8N59kMJUiVH++5QxJzTyHB/wh/kG5LxQ44j9zhUvZmw=
X-Endpoint-Received: by B4 Relay for quic_renjiang@quicinc.com/20241001 with auth_id=235
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series enables support for 4xx venus encode/decode on qcs615.

This DT change is dependent on [1]dts

[1]
https://lore.kernel.org/all/20240926-add_initial_support_for_qcs615-v3-0-e37617e91c62@quicinc.com/

Signed-off-by: Renjiang Han <quic_renjiang@quicinc.com>
---
Renjiang Han (2):
      arm64: dts: qcom: add video DT for qcs615
      media: venus: core: add qcs615 DT compatible and resource data

 arch/arm64/boot/dts/qcom/qcs615-ride.dts | 12 +++++
 arch/arm64/boot/dts/qcom/qcs615.dtsi     | 75 ++++++++++++++++++++++++++++++++
 drivers/media/platform/qcom/venus/core.c | 50 +++++++++++++++++++++
 3 files changed, 137 insertions(+)
---
base-commit: 9e5393d83e3a5cae58bac6d511371b21a9117302
change-id: 20241008-add_qcs615_video-d13e06b63ce5

Best regards,
-- 
Renjiang Han <quic_renjiang@quicinc.com>

