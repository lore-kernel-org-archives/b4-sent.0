From: Vincent Jardin <vjardin@free.fr>
Date: Fri, 27 Nov 2026 23:37:39 +0100
Subject: [PATCH iproute2-next 1/3] uapi: add the attributes of the lisp
 devices
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261127-iproute2-lisp-v1-1-df8ea175bc06@free.fr>
References: <20261127-iproute2-lisp-v1-0-df8ea175bc06@free.fr>
In-Reply-To: <20261127-iproute2-lisp-v1-0-df8ea175bc06@free.fr>
To: David Ahern <dsahern@kernel.org>, 
 Stephen Hemminger <stephen@networkplumber.org>
Cc: netdev@vger.kernel.org, Matthieu Baerts <matttbe@kernel.org>, 
 Vincent Jardin <vjardin@free.fr>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795819063; l=835;
 i=vjardin@free.fr; s=20260525; h=from:subject:message-id;
 bh=90Pl+kHygIdW1VdLUKQtrTeLJu8UNvjTfSyw+LojGJA=;
 b=8NfhLKJZM2eWQhdZ+sX8biCzIKhlUsJZH2N20+GH5fuSf5WUGUOwOB7safB1YlTdIcmD5bSGw
 hQVeCiHZ/KXBccuKoRq25Dew7rWWq2nt+anonMfL0VqzSf56BCK2ZE0
X-Developer-Key: i=vjardin@free.fr; a=ed25519;
 pk=hppgLeFpGpKOi7LNwGEZ4jOYofJCoGd4Jf1ltAabiLw=
X-Endpoint-Received: by B4 Relay for vjardin@free.fr/20260525 with auth_id=871
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Use IFLA_LISP_* from the uAPI header of the kernel

See:
  https://lore.kernel.org/r/20261126-for-upstream-lisp-v1-v1-0-7382a4bcfd9b@free.fr

Signed-off-by: Vincent Jardin <vjardin@free.fr>
---
 include/uapi/linux/if_link.h | 12 ++++++++++++
 1 file changed, 12 insertions(+)

diff --git a/include/uapi/linux/if_link.h b/include/uapi/linux/if_link.h
index 7ce01d81..786a16b3 100644
--- a/include/uapi/linux/if_link.h
+++ b/include/uapi/linux/if_link.h
@@ -1536,6 +1536,18 @@ enum {
 
 #define IFLA_BAREUDP_MAX (__IFLA_BAREUDP_MAX - 1)
 
+/* LISP section */
+enum {
+	IFLA_LISP_UNSPEC,
+	IFLA_LISP_ID,
+	IFLA_LISP_COLLECT_METADATA,
+	IFLA_LISP_LOCAL,
+	IFLA_LISP_LOCAL6,
+	__IFLA_LISP_MAX
+};
+
+#define IFLA_LISP_MAX (__IFLA_LISP_MAX - 1)
+
 /* PPP section */
 enum {
 	IFLA_PPP_UNSPEC,

-- 
2.43.0

