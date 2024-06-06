From: Vincent Whitchurch <vincent.whitchurch@datadoghq.com>
Date: Thu, 06 Jun 2024 11:27:54 +0200
Subject: [PATCH bpf-next 3/5] selftests/bpf: sockmap: Exit with error on
 failure
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240606-sockmap-splice-v1-3-4820a2ab14b5@datadoghq.com>
References: <20240606-sockmap-splice-v1-0-4820a2ab14b5@datadoghq.com>
In-Reply-To: <20240606-sockmap-splice-v1-0-4820a2ab14b5@datadoghq.com>
To: John Fastabend <john.fastabend@gmail.com>, 
 Jakub Sitnicki <jakub@cloudflare.com>
Cc: netdev@vger.kernel.org, bpf@vger.kernel.org, 
 Vincent Whitchurch <vincent.whitchurch@datadoghq.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1717666080; l=739;
 i=vincent.whitchurch@datadoghq.com; s=20240606; h=from:subject:message-id;
 bh=s+cGvRIItR2T1BSyPd1aAjKIAS5wEiDTK0IA+jXP+Lc=;
 b=v+BA4IwBGIyiVcfjNeL6acPzZDr2tvNeA1MJskBYLiNAd04pwDg4drD5MTBtzX0IalFB66io6
 eh+dTuYoP5yCXyu2MG2WdfLo2IlmVGRV1U9mRx9l+paLqlIozs4uobi
X-Developer-Key: i=vincent.whitchurch@datadoghq.com; a=ed25519;
 pk=GwUiPK96WuxbUAD4UjapyK7TOt+aX0EqABOZ/BOj+/M=
X-Endpoint-Received: by B4 Relay for vincent.whitchurch@datadoghq.com/20240606 with auth_id=170
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

If any tests failed, exit the program with a non-zero
error code.

Signed-off-by: Vincent Whitchurch <vincent.whitchurch@datadoghq.com>
---
 tools/testing/selftests/bpf/test_sockmap.c | 4 +++-
 1 file changed, 3 insertions(+), 1 deletion(-)

diff --git a/tools/testing/selftests/bpf/test_sockmap.c b/tools/testing/selftests/bpf/test_sockmap.c
index 9cba4ec844a5..ab7e169f5afa 100644
--- a/tools/testing/selftests/bpf/test_sockmap.c
+++ b/tools/testing/selftests/bpf/test_sockmap.c
@@ -2079,7 +2079,9 @@ int main(int argc, char **argv)
 	close(cg_fd);
 	if (cg_created)
 		cleanup_cgroup_environment();
-	return err;
+	if (err)
+		return err;
+	return failed ? 1 : 0;
 }
 
 void running_handler(int a)

-- 
2.34.1

