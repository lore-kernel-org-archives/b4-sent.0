From: Christoph Paasch <cpaasch@openai.com>
Subject: [PATCH mptcp-next 0/2] mptcp: Add support for SO_MAX_PACING_RATE
Date: Sat, 02 Aug 2025 16:52:21 -0700
Message-Id: <20250802-b4-mptcp_setsockopt-v1-0-50d4905a4c2b@openai.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIALWkjmgC/x2MQQqDMBAAvyJ7diFqS7RfESk22dRFmoRsKIL4d
 0OOAzNzglBiEng1JyT6s3DwBbq2AbOt/kvItjD0qn8qPXT4eeAvZhPfQlmC2UPMaAft3DRaO6k
 RShkTOT7qdYZqo6cjw3JdN61yQuFxAAAA
X-Change-ID: 20250731-b4-mptcp_setsockopt-d37ff98dd908
To: MPTCP Upstream <mptcp@lists.linux.dev>, 
 Matthieu Baerts <matttbe@kernel.org>, Mat Martineau <martineau@kernel.org>, 
 Geliang Tang <geliang@kernel.org>
Cc: Christoph Paasch <cpaasch@openai.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1754178751; l=610;
 i=cpaasch@openai.com; s=20250712; h=from:subject:message-id;
 bh=7wVYYYqU8hSQqetWg1mmRyE9YdNzO1iyrlX3LlU2MSw=;
 b=Ca2j/JLbxGLv8ata9QbPz48m/ekJWzWctVviGnhOCETcUqW7TjrzR1G5mubeQdHL6NVV1ARYh
 7F1zMDCSXegBCAr1JPnw7fq2smqoyaGUp+5v6u4qVBMP55QdBWgWzrc
X-Developer-Key: i=cpaasch@openai.com; a=ed25519;
 pk=1HRHZlVUZPziMZvsAQFvP7n5+uEosTDAjXmNXykdxdg=
X-Endpoint-Received: by B4 Relay for cpaasch@openai.com/20250712 with auth_id=459
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Pass it to all subflows. Also, add a selftest.

Signed-off-by: Christoph Paasch <cpaasch@openai.com>
---
Christoph Paasch (2):
      mptcp: Add support for SO_MAX_PACING_RATE
      selftests: Add tests for SO_MAX_PACING_RATE

 net/mptcp/sockopt.c                               | 31 +++++++++-
 tools/testing/selftests/net/mptcp/mptcp_sockopt.c | 74 +++++++++++++++++++++++
 2 files changed, 104 insertions(+), 1 deletion(-)
---
base-commit: 9a3f9440d3f1ba4d323e6dc3f503e453b15a4edc
change-id: 20250731-b4-mptcp_setsockopt-d37ff98dd908

Best regards,
-- 
Christoph Paasch <cpaasch@openai.com>

