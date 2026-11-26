From: Joel Granados <joel.granados@kernel.org>
Date: Thu, 26 Nov 2026 12:47:45 +0100
Subject: [PATCH RFC 5/9] net: sysctl: Add sysctl registration to networking
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261126-lklm-sysctl-ctx-flatarray-v1-5-d7fc9cc9b03e@kernel.org>
References: <20261126-lklm-sysctl-ctx-flatarray-v1-0-d7fc9cc9b03e@kernel.org>
In-Reply-To: <20261126-lklm-sysctl-ctx-flatarray-v1-0-d7fc9cc9b03e@kernel.org>
To: Kees Cook <kees@kernel.org>, Alexey Gladkov <legion@kernel.org>, 
 David Laight <david.laight.linux@gmail.com>, Wen Yang <wen.yang@linux.dev>
Cc: Eric Dumazet <edumazet@kernel.org>, Jakub Kicinski <kuba@kernel.org>, 
 Paolo Abeni <pabeni@redhat.com>, Simon Horman <horms@kernel.org>, 
 Linus Torvalds <torvalds@linux-foundation.org>, 
 linux-kernel@vger.kernel.org, linux-fsdevel@vger.kernel.org, 
 netdev@vger.kernel.org, Joel Granados <joel.granados@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=3478;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=BjxePkqZQh7SmQ/XefseKj5Jh2846+Y/W+u6eGkfSy4=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGsIHGTHmbMrlU8rxlvUU0JesTYVV5pzN8ar5
 l2w8K9JUbkfY4kBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJrCBxkAAoJELqXzVK3
 lkFPVPsL/iy1EnZYmVK2EHHCFf5ovFyK1uRFgYUBiPejvYnDYPhwGkB/NkT/LqIeSKLSLkOFWO/
 1exdqhA0TbTrur1c0YOMTxwM0i/hxZFjeH3PU2lDPjxA4Bl6nz6Pv5dVSHXoL/M0EP73oACNO0h
 tzvZtgmWiM4zrNg4xIXFExIj6+vc209hZHnESk/QwQrLH05ZXBhmT/quqVC7XnI3KEOlrrAWOCa
 couIamwZUx/7/WpMVZk68epOleIaydzUy5O/Ur7xfWQvhPqQSw/3s8KrfsSg0jd7Ch73auBC0Nh
 Rc1WYB/xSybY6IEaCrdOVs4aCS4xCwSuaGsbKfiGnj7quVy0kkStENK/oN4Gr4SfuzvUb8K77qy
 0QYHI15ifgYb79+QnrV/CTfLrcS9q5tj1wZYWCUTH6lsJ4/JOSkw2ZrxmjQuoSqp2JCqJJ+JFNH
 fAFEODHxjZn68D8BxPdX4CtAw3qt+8eA5mFtPC0W46v9Fay+JZ81PUZKUjiaonLduTT1VHNilU5
 +Y=
X-Developer-Key: i=joel.granados@kernel.org; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for joel.granados@kernel.org/default with auth_id=239
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the per-netns entry point for template registration. It takes the
shared template and the caller's overlay and registers in the
namespace's set through __register_sysctl_table_tmpl(). Run
ensure_safe_net_sysctl() on the overlay for namespaces other than
init_net.

Signed-off-by: Joel Granados <joel.granados@kernel.org>
---
 include/net/net_namespace.h | 14 ++++++++++++++
 net/sysctl_net.c            | 25 +++++++++++++++++++++++++
 2 files changed, 39 insertions(+)

diff --git a/include/net/net_namespace.h b/include/net/net_namespace.h
index c29a22ca178fa678c0468247b9f85f53eec86184..ecec120de3081d7e8f5c13b72ca98dc647704139 100644
--- a/include/net/net_namespace.h
+++ b/include/net/net_namespace.h
@@ -527,11 +527,19 @@ struct ctl_table;
 
 #define register_net_sysctl(net, path, table)	\
 	register_net_sysctl_sz(net, path, table, ARRAY_SIZE(table))
+#define register_net_sysctl_tmpl(net, path, tmpl, overlay)		\
+	register_net_sysctl_tmpl_sz(net, path, CTL_TABLE_TMPL(tmpl),	\
+				    overlay, ARRAY_SIZE(tmpl))
 #ifdef CONFIG_SYSCTL
 int net_sysctl_init(void);
 struct ctl_table_header *register_net_sysctl_sz(struct net *net, const char *path,
 						const struct ctl_table *table,
 						size_t table_size);
+struct ctl_table_header *register_net_sysctl_tmpl_sz(struct net *net,
+						     const char *path,
+						     const struct ctl_table_tmpl *tmpl,
+						     const struct ctl_table *overlay,
+						     size_t table_size);
 void unregister_net_sysctl_table(struct ctl_table_header *header);
 #else
 static inline int net_sysctl_init(void) { return 0; }
@@ -540,6 +548,12 @@ static inline struct ctl_table_header *register_net_sysctl_sz(struct net *net,
 {
 	return NULL;
 }
+static inline struct ctl_table_header *register_net_sysctl_tmpl_sz(
+	struct net *net, const char *path, const struct ctl_table_tmpl *tmpl,
+	const struct ctl_table *overlay, size_t table_size)
+{
+	return NULL;
+}
 static inline void unregister_net_sysctl_table(struct ctl_table_header *header)
 {
 }
diff --git a/net/sysctl_net.c b/net/sysctl_net.c
index e190a639eef2f6929c4aed85ad625aaf8a6ebd6a..c6eae05dedaecc3bdce402741140d8690d3c15ea 100644
--- a/net/sysctl_net.c
+++ b/net/sysctl_net.c
@@ -173,6 +173,31 @@ struct ctl_table_header *register_net_sysctl_sz(struct net *net,
 }
 EXPORT_SYMBOL_GPL(register_net_sysctl_sz);
 
+/**
+ * register_net_sysctl_tmpl_sz - register a shared template for one netns
+ * @net: the network namespace
+ * @path: path of the directory under /proc/sys
+ * @tmpl: the template every namespace shares, see register_sysctl_tmpl_sz()
+ * @overlay: copy of @tmpl holding values for @net; this ptr is not kept!
+ * @table_size: number of entries in @tmpl and @overlay
+ *
+ * The safety check runs on @overlay, since that is what @net will see
+ */
+struct ctl_table_header *register_net_sysctl_tmpl_sz(struct net *net,
+						     const char *path,
+						     const struct ctl_table_tmpl *tmpl,
+						     const struct ctl_table *overlay,
+						     size_t table_size)
+{
+	if (!net_eq(net, &init_net))
+		if (ensure_safe_net_sysctl(net, path, overlay, table_size))
+			return NULL;
+
+	return __register_sysctl_table_tmpl(&net->sysctls, path, tmpl, overlay,
+					    table_size);
+}
+EXPORT_SYMBOL_GPL(register_net_sysctl_tmpl_sz);
+
 void unregister_net_sysctl_table(struct ctl_table_header *header)
 {
 	unregister_sysctl_table(header);

-- 
2.50.1

