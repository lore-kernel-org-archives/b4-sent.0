From: Dikshita Agarwal <quic_dikshita@quicinc.com>
Date: Tue, 27 Aug 2024 15:35:54 +0530
Subject: [PATCH v3 29/29] media: iris: add check to allow sub states
 transitions
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240827-iris_v3-v3-29-c5fdbbe65e70@quicinc.com>
References: <20240827-iris_v3-v3-0-c5fdbbe65e70@quicinc.com>
In-Reply-To: <20240827-iris_v3-v3-0-c5fdbbe65e70@quicinc.com>
To: Vikash Garodia <quic_vgarodia@quicinc.com>, 
 Abhinav Kumar <quic_abhinavk@quicinc.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Philipp Zabel <p.zabel@pengutronix.de>
Cc: linux-media@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Dikshita Agarwal <quic_dikshita@quicinc.com>, 
 Vedang Nagar <quic_vnagar@quicinc.com>
X-Mailer: b4 0.15-dev
X-Developer-Signature: v=1; a=ed25519-sha256; t=1724753191; l=4597;
 i=quic_dikshita@quicinc.com; s=20240826; h=from:subject:message-id;
 bh=2EGrcsprZLpn6qAzmt8V0SRE4y1luktgGIACm9k/2VE=;
 b=7+MuEKA+zwz6gaIbmSjqsqr4G/QiPXTFv4WrtXRxQay//0VRqtWaLeJ4SSxndZZhdVbnsVHHz
 QwATFuYhcllAugnP9VBcyWrTgH7G4fJP4AwyCALfQqXRjnztrPj3L5h
X-Developer-Key: i=quic_dikshita@quicinc.com; a=ed25519;
 pk=+c7562uu1Y968VTv9z59ch2v3jmlO2Qv3uX7srN3LJY=
X-Endpoint-Received: by B4 Relay for quic_dikshita@quicinc.com/20240826 with auth_id=199
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Vedang Nagar <quic_vnagar@quicinc.com>

Based on state machine design, add allow checks to
transition from one sub-state to another sub-states.

Signed-off-by: Vedang Nagar <quic_vnagar@quicinc.com>
Signed-off-by: Dikshita Agarwal <quic_dikshita@quicinc.com>
---
 .../platform/qcom/iris/iris_hfi_gen1_command.c     | 12 ++++++-
 drivers/media/platform/qcom/iris/iris_state.c      | 42 ++++++++++++++++++++++
 drivers/media/platform/qcom/iris/iris_state.h      |  1 +
 3 files changed, 54 insertions(+), 1 deletion(-)

diff --git a/drivers/media/platform/qcom/iris/iris_hfi_gen1_command.c b/drivers/media/platform/qcom/iris/iris_hfi_gen1_command.c
index 17333768afa2..2f3e40368cce 100644
--- a/drivers/media/platform/qcom/iris/iris_hfi_gen1_command.c
+++ b/drivers/media/platform/qcom/iris/iris_hfi_gen1_command.c
@@ -135,6 +135,9 @@ static int iris_hfi_gen1_session_start(struct iris_inst *inst, u32 plane)
 	if (!V4L2_TYPE_IS_OUTPUT(plane))
 		return 0;
 
+	if (inst->sub_state & IRIS_INST_SUB_LOAD_RESOURCES)
+		return 0;
+
 	reinit_completion(&inst->completion);
 	iris_hfi_gen1_packet_session_cmd(inst, &packet, HFI_CMD_SESSION_LOAD_RESOURCES);
 
@@ -153,7 +156,11 @@ static int iris_hfi_gen1_session_start(struct iris_inst *inst, u32 plane)
 	if (ret)
 		return ret;
 
-	return iris_wait_for_session_response(inst, false);
+	ret = iris_wait_for_session_response(inst, false);
+	if (ret)
+		return ret;
+
+	return iris_inst_change_sub_state(inst, 0, IRIS_INST_SUB_LOAD_RESOURCES);
 }
 
 static int iris_hfi_gen1_session_stop(struct iris_inst *inst, u32 plane)
@@ -180,6 +187,9 @@ static int iris_hfi_gen1_session_stop(struct iris_inst *inst, u32 plane)
 		ret = iris_hfi_queue_cmd_write(core, &pkt, pkt.shdr.hdr.size);
 		if (!ret)
 			ret = iris_wait_for_session_response(inst, false);
+
+		iris_inst_change_sub_state(inst, IRIS_INST_SUB_LOAD_RESOURCES, 0);
+
 		iris_helper_buffers_done(inst, V4L2_BUF_TYPE_VIDEO_OUTPUT_MPLANE,
 					 VB2_BUF_STATE_ERROR);
 		iris_helper_buffers_done(inst, V4L2_BUF_TYPE_VIDEO_CAPTURE_MPLANE,
diff --git a/drivers/media/platform/qcom/iris/iris_state.c b/drivers/media/platform/qcom/iris/iris_state.c
index 1c7437bc808b..ab7dc768ef25 100644
--- a/drivers/media/platform/qcom/iris/iris_state.c
+++ b/drivers/media/platform/qcom/iris/iris_state.c
@@ -165,6 +165,45 @@ int iris_inst_state_change_streamoff(struct iris_inst *inst, u32 plane)
 	return iris_inst_change_state(inst, new_state);
 }
 
+static int iris_inst_allow_sub_state(struct iris_inst *inst, enum iris_inst_sub_state sub_state)
+{
+	if (!sub_state)
+		return true;
+
+	switch (inst->state) {
+	case IRIS_INST_INIT:
+		if (sub_state & IRIS_INST_SUB_LOAD_RESOURCES)
+			return true;
+		break;
+	case IRIS_INST_INPUT_STREAMING:
+		if (sub_state & (IRIS_INST_SUB_FIRST_IPSC | IRIS_INST_SUB_DRC |
+			IRIS_INST_SUB_DRAIN | IRIS_INST_SUB_INPUT_PAUSE))
+			return true;
+		break;
+	case IRIS_INST_OUTPUT_STREAMING:
+		if (sub_state & (IRIS_INST_SUB_DRC_LAST |
+			IRIS_INST_SUB_DRAIN_LAST | IRIS_INST_SUB_OUTPUT_PAUSE))
+			return true;
+		break;
+	case IRIS_INST_STREAMING:
+		if (sub_state & (IRIS_INST_SUB_DRC | IRIS_INST_SUB_DRAIN |
+			IRIS_INST_SUB_DRC_LAST | IRIS_INST_SUB_DRAIN_LAST |
+			IRIS_INST_SUB_INPUT_PAUSE | IRIS_INST_SUB_OUTPUT_PAUSE))
+			return true;
+		break;
+	case IRIS_INST_DEINIT:
+		if (sub_state & (IRIS_INST_SUB_DRC | IRIS_INST_SUB_DRAIN |
+			IRIS_INST_SUB_DRC_LAST | IRIS_INST_SUB_DRAIN_LAST |
+			IRIS_INST_SUB_INPUT_PAUSE | IRIS_INST_SUB_OUTPUT_PAUSE))
+			return true;
+		break;
+	default:
+		return false;
+	}
+
+	return false;
+}
+
 int iris_inst_change_sub_state(struct iris_inst *inst,
 			       enum iris_inst_sub_state clear_sub_state,
 			       enum iris_inst_sub_state set_sub_state)
@@ -184,6 +223,9 @@ int iris_inst_change_sub_state(struct iris_inst *inst,
 
 	prev_sub_state = inst->sub_state;
 
+	if (!iris_inst_allow_sub_state(inst, set_sub_state))
+		return -EINVAL;
+
 	inst->sub_state |= set_sub_state;
 	inst->sub_state &= ~clear_sub_state;
 
diff --git a/drivers/media/platform/qcom/iris/iris_state.h b/drivers/media/platform/qcom/iris/iris_state.h
index 9516425fcfa7..f60dc18ca30e 100644
--- a/drivers/media/platform/qcom/iris/iris_state.h
+++ b/drivers/media/platform/qcom/iris/iris_state.h
@@ -124,6 +124,7 @@ enum iris_inst_sub_state {
 	IRIS_INST_SUB_DRAIN_LAST	= BIT(4),
 	IRIS_INST_SUB_INPUT_PAUSE	= BIT(5),
 	IRIS_INST_SUB_OUTPUT_PAUSE	= BIT(6),
+	IRIS_INST_SUB_LOAD_RESOURCES	= BIT(7),
 };
 
 void iris_change_core_state(struct iris_core *core,

-- 
2.34.1

