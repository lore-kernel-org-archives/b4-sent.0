From: Lawrence Lin <deduce@gmail.com>
Date: Sun, 04 Oct 2026 14:51:00 -0500
Subject: [PATCH v2 1/2] module: Add module_kallsyms_on_each_addr()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261004-ftrace-mod-bsearch-v2-1-c1de73e72e73@gmail.com>
References: <20261004-ftrace-mod-bsearch-v2-0-c1de73e72e73@gmail.com>
In-Reply-To: <20261004-ftrace-mod-bsearch-v2-0-c1de73e72e73@gmail.com>
To: Steven Rostedt <rostedt@goodmis.org>, 
 Masami Hiramatsu <mhiramat@kernel.org>, Mark Rutland <mark.rutland@arm.com>, 
 Mathieu Desnoyers <mathieu.desnoyers@efficios.com>, 
 Luis Chamberlain <mcgrof@kernel.org>, Petr Pavlu <petr.pavlu@suse.com>, 
 Daniel Gomez <da.gomez@kernel.org>, Sami Tolvanen <samitolvanen@google.com>
Cc: Aaron Tomlin <atomlin@atomlin.com>, Stanislaw Gruszka <stf_xl@wp.pl>, 
 David Laight <david.laight.linux@gmail.com>, 
 =?utf-8?q?Krzysztof_Wilczy=C5=84ski?= <kwilczynski@kernel.org>, 
 linux-modules@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-trace-kernel@vger.kernel.org, Lawrence Lin <deduce@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791143460; l=4432;
 i=deduce@gmail.com; s=default; h=from:subject:message-id;
 bh=k9sVJtA4GmO4insrdVQIsMOHURF52X3DDft+AQtZiU0=;
 b=cQGCT24hVcy765hus5EhJrrhotjF27h0usQPeS0UBItv3lt2+2iuXfw8/YuN6wxfWXWNh90Oy
 VlibwCFvldXDjPqAUkHMkXdOglwq5UyKZ9SGkXc6jTb/Jy/K11fwXQO
X-Developer-Key: i=deduce@gmail.com; a=ed25519;
 pk=Ws6hmG/zoco3lMoykbeaYjo9S7a6sDddQY8EALjp9cM=
X-Endpoint-Received: by B4 Relay for deduce@gmail.com/default with auth_id=1106
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

ftrace needs the addresses of the symbols of a module while the module is
still being loaded: ftrace_module_init() runs before complete_formation(),
while the module is MODULE_STATE_UNFORMED, and
module_kallsyms_on_each_symbol() skips unformed modules. It also needs
exactly the symbols that find_kallsyms_symbol() may resolve an address
to, so that it agrees with kallsyms_lookup().

Factor the symbol filter of find_kallsyms_symbol() into is_lookup_symbol()
and add module_kallsyms_on_each_addr(), which calls a function with the
address of each such symbol of a given module. Like find_kallsyms_symbol(),
it reads mod->kallsyms under RCU, which add_kallsyms() has set up by then.

No functional change to find_kallsyms_symbol().

Assisted-by: Claude:claude-opus-5-5
Signed-off-by: Lawrence Lin <deduce@gmail.com>
---
 include/linux/module.h   | 10 ++++++++++
 kernel/module/kallsyms.c | 44 +++++++++++++++++++++++++++++++++++---------
 2 files changed, 45 insertions(+), 9 deletions(-)

diff --git a/include/linux/module.h b/include/linux/module.h
index 96cc98568eea..8b1c06d1118c 100644
--- a/include/linux/module.h
+++ b/include/linux/module.h
@@ -971,6 +971,10 @@ unsigned long module_kallsyms_lookup_name(const char *name);
 
 unsigned long find_kallsyms_symbol_value(struct module *mod, const char *name);
 
+void module_kallsyms_on_each_addr(struct module *mod,
+				  void (*fn)(void *, unsigned long),
+				  void *data);
+
 #else	/* CONFIG_MODULES && CONFIG_KALLSYMS */
 
 static inline int module_kallsyms_on_each_symbol(const char *modname,
@@ -1014,6 +1018,12 @@ static inline unsigned long find_kallsyms_symbol_value(struct module *mod,
 	return 0;
 }
 
+static inline void module_kallsyms_on_each_addr(struct module *mod,
+						void (*fn)(void *, unsigned long),
+						void *data)
+{
+}
+
 #endif  /* CONFIG_MODULES && CONFIG_KALLSYMS */
 
 /* Define __free(module_put) macro for struct module *. */
diff --git a/kernel/module/kallsyms.c b/kernel/module/kallsyms.c
index f23126d804b2..bccee4b8294c 100644
--- a/kernel/module/kallsyms.c
+++ b/kernel/module/kallsyms.c
@@ -246,6 +246,18 @@ static const char *kallsyms_symbol_name(struct mod_kallsyms *kallsyms, unsigned
 	return kallsyms->strtab + kallsyms->symtab[symnum].st_name;
 }
 
+/*
+ * Whether find_kallsyms_symbol() may resolve an address to symbol @symnum.
+ * Unnamed symbols are ignored: they're uninformative and inserted at a whim.
+ */
+static bool is_lookup_symbol(struct mod_kallsyms *kallsyms, unsigned int symnum)
+{
+	const char *name = kallsyms_symbol_name(kallsyms, symnum);
+
+	return kallsyms->symtab[symnum].st_shndx != SHN_UNDEF &&
+	       *name != '\0' && !is_mapping_symbol(name);
+}
+
 /*
  * Given a module and address, find the corresponding symbol and return its name
  * while providing its size and offset if needed.
@@ -286,15 +298,7 @@ static const char *find_kallsyms_symbol(struct module *mod,
 		const Elf_Sym *sym = &kallsyms->symtab[i];
 		unsigned long thisval = kallsyms_symbol_value(sym);
 
-		if (sym->st_shndx == SHN_UNDEF)
-			continue;
-
-		/*
-		 * We ignore unnamed symbols: they're uninformative
-		 * and inserted at a whim.
-		 */
-		if (*kallsyms_symbol_name(kallsyms, i) == '\0' ||
-		    is_mapping_symbol(kallsyms_symbol_name(kallsyms, i)))
+		if (!is_lookup_symbol(kallsyms, i))
 			continue;
 
 		if (thisval <= addr && thisval > bestval) {
@@ -458,6 +462,28 @@ unsigned long find_kallsyms_symbol_value(struct module *mod, const char *name)
 	return __find_kallsyms_symbol_value(mod, name);
 }
 
+/*
+ * Call @fn with the address of each symbol of @mod that find_kallsyms_symbol()
+ * may resolve an address to. Unlike module_kallsyms_on_each_symbol(), this
+ * also works while @mod is still being loaded.
+ */
+void module_kallsyms_on_each_addr(struct module *mod,
+				  void (*fn)(void *, unsigned long),
+				  void *data)
+{
+	struct mod_kallsyms *kallsyms;
+	unsigned int i;
+
+	guard(rcu)();
+	kallsyms = rcu_dereference(mod->kallsyms);
+
+	/* ELF starts real symbols at 1. */
+	for (i = 1; i < kallsyms->num_symtab; i++) {
+		if (is_lookup_symbol(kallsyms, i))
+			fn(data, kallsyms_symbol_value(&kallsyms->symtab[i]));
+	}
+}
+
 int module_kallsyms_on_each_symbol(const char *modname,
 				   int (*fn)(void *, const char *, unsigned long),
 				   void *data)

-- 
2.55.0

