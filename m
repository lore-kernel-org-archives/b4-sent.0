From: Levi Zim <rsworktech@outlook.com>
Date: Fri, 27 Sep 2024 14:52:29 +0800
Subject: [PATCH] dup.2: Add ENOMEM to ERRORS
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240927-dup2-v1-1-12ecc79167d5@outlook.com>
X-B4-Tracking: v=1; b=H4sIACxW9mYC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIxMDSyNz3ZTSAiNdcyPzVEsLs1RDSwMDJaDSgqLUtMwKsDHRsbW1ACQQ8Il
 WAAAA
X-Change-ID: 20240927-dup2-727e986e1900
To: linux-man@vger.kernel.org
Cc: Linux API <linux-api@vger.kernel.org>, 
 Levi Zim <rsworktech@outlook.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1277;
 i=rsworktech@outlook.com; h=from:subject:message-id;
 bh=WlIAO1mmcIQbRV8l8FS+BAcsh1rqVPTGYW1EOb7BydQ=;
 b=owEBbQKS/ZANAwAIAW87mNQvxsnYAcsmYgBm9lZCu+Ky5T0AQ2EUB/Q8m+ikUppvTf5hC86fT
 GAVS9GjICCJAjMEAAEIAB0WIQQolnD5HDY18KF0JEVvO5jUL8bJ2AUCZvZWQgAKCRBvO5jUL8bJ
 2COJD/0fLyAlWF+2IOOQeGVFF8Gn9EbRqiotZGkyQFbEAPbPPrpY6o704u7v22jXcLYfwwswF2s
 wZ5dJKIv67HYW57AOBBQNWhPSzygMHb4BD3BxfPFSy9nGsMHCKZ0l8oiYENa8zY4sh2j+iq6fjJ
 JQQyDlfSR5vn4BiZdcBnwJc+tqpRIWnKNWzu2ORgpQLGmM856G6f8tgWXg/dOYaLnBffKzXi8fF
 230c9f6OU4Gg98ctngfvn9wsBdEMrCqLCYdn5frkybHk0MMwie0XvVlpgd9UNu8ixBz1ikGcqrU
 dFAO9sR/8L4rDE3axKl+uUcN4PXfM9hPe5RPkuMYHiF9YX/+KuyEsNjbN9CY+RyBRL5cKmmILHz
 sl3wo4SyxqSduTJw36ieGzWB4uUPX+YyJRVOfki0N4+kCTomlzEZ8HIHwf+Ts/7WG10SgPKBTk6
 nahzQlPkWNS3JiXRhad4WOYY2B30Gnqic4JbhsCNaWsYmdMzll9Dr5rOVNgkiniQbb1MqVtIeW2
 JmtOC7cGzhs7Hj5fgvO9T55LqSvfucSQKagnME8H0ROzcEaupt+qHJhPQJdHDQa7yv5SqXGVzEr
 mSOjgwa2W38hSPkTBlE2FMikatjQZISNzh3WKba6Mj4X7FSFauCTB+IBR4Stoi8+Tgy3CfDy+Di
 RWR0GmzKy2gTk1g==
X-Developer-Key: i=rsworktech@outlook.com; a=openpgp;
 fpr=17AADD6726DDC58B8EE5881757670CCFA42CCF0A
X-Endpoint-Received: by B4 Relay for rsworktech@outlook.com/default with auth_id=219
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

dup2 could return ENOMEM under extreme condition.
For example, when sysctl fs.nr_open=2147483584, and RLIMIT_NOFILE is also
2147483584. The following program fails with ENOMEM:

int main(){
  int ret = dup2(0, 2000000000);
  if (ret < 0) {
    perror("dup2");
    return 1;
  }
  return 0;
}

This ENOMEM comes from an allocation error here:
https://elixir.bootlin.com/linux/v6.1/source/mm/util.c#L596

ENOMEM is already documented for open(2).

Signed-off-by: Levi Zim <rsworktech@outlook.com>
---
While experimenting with fs.nr_open sysctl and RLIMIT_NOFILE,
I noticed that dup(2) could return an undocumented errno ENOMEM.
This patch add ENOMEM to ERRORS in dup.2.
---
 man/man2/dup.2 | 3 +++
 1 file changed, 3 insertions(+)

diff --git a/man/man2/dup.2 b/man/man2/dup.2
index ee964a827ca062d90419c7d39f457de270d42ca3..719f0ae9e78165733cbe607bbf8a803a5d0943b4 100644
--- a/man/man2/dup.2
+++ b/man/man2/dup.2
@@ -197,6 +197,9 @@ .SH ERRORS
 .B RLIMIT_NOFILE
 in
 .BR getrlimit (2)).
+.TP
+.B ENOMEM
+Insufficient kernel memory was available.
 .SH STANDARDS
 .TP
 .BR dup ()

---
base-commit: 1e2d36deb2de1dbaf7084bb7dc3cb2c170cce852
change-id: 20240927-dup2-727e986e1900

Best regards,
-- 
Levi Zim <rsworktech@outlook.com>

