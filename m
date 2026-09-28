From: David Heidelberg <david@ixit.cz>
Subject: [PATCH 0/2] media: venus: vdec: fix drain and restart on SDM845
Date: Mon, 28 Sep 2026 23:40:13 +0200
Message-Id: <20260928-venus-vdec-eos-v1-0-6e9eb3ce9849@ixit.cz>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQqDMBBG4avIrDuQBJXqVUoXMf5tx0UsmRoE8
 e7GuvwW722kSAKlvtooIYvKHAvsraLw8fENlrGYnHGt6dydM+KinEcExqzc+bqxvg6maS2V6Jv
 wkvU/fDwv6zJMCL/zQvt+AAvQkOVyAAAA
X-Change-ID: 20260928-venus-vdec-eos-9a451a4c0561
To: Vikash Garodia <vikash.garodia@oss.qualcomm.com>, 
 Dikshita Agarwal <dikshita.agarwal@oss.qualcomm.com>, 
 Bryan O'Donoghue <bod@kernel.org>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Stanimir Varbanov <stanimir.varbanov@linaro.org>
Cc: Mauro Carvalho Chehab <mchehab+samsung@kernel.org>, 
 linux-media@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 linux-kernel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1464; i=david@ixit.cz;
 h=from:subject:message-id; bh=3ZDzdFxYbJYm7xzCv+PHC/iaTeit9v8RwfIAsE0clT4=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqut7D4EvnI7g1BCftzqiI5Jzk00BNd6j49Exb7
 P1488/HvAWJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCarrewwAKCRBgAj/E00kg
 ck8yD/48gW59S9RsF7T7X7Avvxe6iBcrg9a+24rm6hk3cqEXLnBpAKpnn1dK070foZ/GVZJrQki
 V6H7PQAKpRT293v4LwbJHpuBlm+XqAs7i5loe/omqzTM2vB2alQLoxUCOibggDzBSCQACQ//BGB
 t0RdT+T/gGWL3LMcPRqN9c6KnRWhg2a/gp1x9L43F4XsFSceofUAsIgvjS1/61w+0Lj6gqa3Nm4
 I+5s2aaQce4T+FLdK5yppFkqlmMzIzH9He/kmvKVsSUhMzzM1wVjhK8eUR1nCTMDI/hrklEJuwh
 nm39GBAQX9RzhGRZPfsuJvR2E4VG93szgi+pJH5aJymSZHDTG+9flXdfGBpO1AKxeT28xW8CVzI
 JRvhlbfx00XtEBgoXxQGRxdpFjOMTfAoFDrBDKu+pjnuld7kCufJ1cX7+OAjgZQOhkZDLqF2DO/
 ZrBL65hifpSOa3gO+Wuq4FU40WWQPJqPoRHOC16SHqJnCPCwwOxW9eCngNOnyiS/7o7VDPQiWFf
 vtgHVHwRLldzbeZ/TZbDd9wz5g+iOFxtLG73OFJ1uQq1aw0HB9hNDbbsr1TmBeCqk1WTVs5+Awu
 uLQju7vfvOMfUl84LD45/bYsoNOe+Y5BpM/bCwYFKEgntrtDfB862kbRmWoayt1CWnAdqhQF/br
 EzTiiDelUd6LhEg==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Please consider this more as a bug-report than the proper fix.

On SDM845 (Venus v4) every V4L2_DEC_CMD_STOP kills the decoder
session: the firmware rejects the dummy 0xdeadb000 address of
the EOS buffer with HFI_ERR_SESSION_FATAL, both queues go into error
and userspace sees poll() fail at the end of every stream.

Patch 1 hands the firmware a real, mapped buffer for EOS, after which
the drain completes as designed: every frame is returned and the last
capture buffer is flagged.

Patch 2 fixes restarting after a seek when CAPTURE is streamed on before
OUTPUT, which left the decoder without any capture or DPB buffers.

Tested on Pixel 3 (blueline) with H.264: output is bit-exact against
ffmpeg's software decoder including the final frames, and drain,
DEC_CMD_START, seek with either queue order, and mid-stream seek all
return every frame followed by a LAST buffer.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
David Heidelberg (2):
      media: venus: vdec: signal EOS with a real buffer
      media: venus: vdec: Start capture after a seek that streams CAPTURE first

 drivers/media/platform/qcom/venus/core.h |  4 +++
 drivers/media/platform/qcom/venus/vdec.c | 51 +++++++++++++++++++++++++++++---
 2 files changed, 51 insertions(+), 4 deletions(-)
---
base-commit: 7079a12d7506b07fb53b54a664bfad5fa9b16d70
change-id: 20260928-venus-vdec-eos-9a451a4c0561

Best regards,
--  
David Heidelberg <david@ixit.cz>

