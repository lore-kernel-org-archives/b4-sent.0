From: Petr Hodina <petr.hodina@protonmail.com>
Date: Fri, 11 Sep 2026 20:18:48 +0200
Subject: [PATCH 2/4] common: Add command line parameter masking
 functionality
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260911-b4-android-bootargs-carryover-v1-2-6ebb43da3df0@protonmail.com>
References: <20260911-b4-android-bootargs-carryover-v1-0-6ebb43da3df0@protonmail.com>
In-Reply-To: <20260911-b4-android-bootargs-carryover-v1-0-6ebb43da3df0@protonmail.com>
To: u-boot@lists.u-boot-project.org
Cc: Tom Rini <trini@konsulko.com>, 
 Neil Armstrong <neil.armstrong@linaro.org>, Peng Fan <peng.fan@nxp.com>, 
 Simon Glass <sjg@chromium.org>, Kory Maincent <kory.maincent@bootlin.com>, 
 Ilias Apalodimas <ilias.apalodimas@linaro.org>, 
 Kuan-Wei Chiu <visitorckw@gmail.com>, 
 Raymond Mao <raymond.mao@riscstar.com>, 
 Quentin Schulz <quentin.schulz@cherry.de>, 
 Philip Molloy <philip.molloy@analog.com>, 
 Jerome Forissier <jerome.forissier@arm.com>, 
 Markus Niebel <Markus.Niebel@ew.tq-group.com>, 
 Alexey Charkov <alchark@gmail.com>, Heiko Schocher <hs@nabladev.com>, 
 Marek Vasut <marek.vasut+renesas@mailbox.org>, 
 Anshul Dalal <anshuld@ti.com>, Heinrich Schuchardt <xypron.glpk@gmx.de>, 
 David Heidelberg <david@ixit.cz>, Petr Pavlata <petr@acrux.cz>, 
 Petr Hodina <petr.hodina@protonmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789150739; l=4681;
 i=petr.hodina@protonmail.com; s=20260107; h=from:subject:message-id;
 bh=x9zxeiR0oC68kj6krUFAO8+pGh69IAz5yDuBqH8tHJ4=;
 b=TOYFTGNY/VpAUvfmwFBjv9cm+dtGg6/vQ6Th37r9PDaLYDHJsgjWmUFNmcg3qodEtKf6mBL7D
 PJgZ6VgxqNcBNF0CsoekWlvvX9OeFGpKwXfzkGmqZdrABUuk4WYgZZ1
X-Developer-Key: i=petr.hodina@protonmail.com; a=ed25519;
 pk=3QaVc6AaAu1IsyyH86+LIOOFhD7kCws8Xhe+wwyE7Bg=
X-Endpoint-Received: by B4 Relay for petr.hodina@protonmail.com/20260107 with auth_id=594
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Extend cmdline_utils to support masking or replacing parameters in
command line strings. This is useful for filtering sensitive data or
modifying boot parameters.

Signed-off-by: Petr Hodina <petr.hodina@protonmail.com>
---
 include/cmdline_utils.h |   7 +++
 lib/cmdline_utils.c     | 150 ++++++++++++++++++++++++++++++++++++++++++++++++
 2 files changed, 157 insertions(+)

diff --git a/include/cmdline_utils.h b/include/cmdline_utils.h
index cf127b64e55..fa6e20b2417 100644
--- a/include/cmdline_utils.h
+++ b/include/cmdline_utils.h
@@ -18,4 +18,11 @@ struct cmdline_param {
 
 int parse_cmdline_params(const char *cmdline, struct cmdline_param *params, int count);
 
+struct cmdline_mask_param {
+	const char *key;
+	const char *new_value;
+};
+
+char *mask_cmdline_params(const char *cmdline, struct cmdline_mask_param *params, int count);
+
 #endif /* _CMDLINE_UTILS_H_ */
diff --git a/lib/cmdline_utils.c b/lib/cmdline_utils.c
index b4798c439b8..4355bdd45f4 100644
--- a/lib/cmdline_utils.c
+++ b/lib/cmdline_utils.c
@@ -94,3 +94,153 @@ cleanup_error:
 	}
 	return -ENOMEM;
 }
+
+static int ensure_capacity(char **result, int *result_len, char **dst_pos, int needed)
+{
+	int current_pos = *dst_pos - *result;
+	char *temp;
+
+	if (current_pos + needed < *result_len)
+		return 0;
+
+	while (current_pos + needed >= *result_len)
+		*result_len *= 2;
+
+	temp = realloc(*result, *result_len + 1);
+	if (!temp) {
+		free(*result);
+		return -ENOMEM;
+	}
+
+	*result = temp;
+	*dst_pos = *result + current_pos;
+
+	return 0;
+}
+
+static int write_replacement(char **result, int *result_len, char **dst_pos,
+			     const char *key_with_equals, const char *new_value)
+{
+	int key_len = strlen(key_with_equals);
+	int new_value_len = strlen(new_value);
+
+	if (ensure_capacity(result, result_len, dst_pos, key_len + new_value_len))
+		return -ENOMEM;
+
+	memcpy(*dst_pos, key_with_equals, key_len);
+	*dst_pos += key_len;
+
+	strcpy(*dst_pos, new_value);
+	*dst_pos += new_value_len;
+
+	return 0;
+}
+
+enum match_result {
+	NO_MATCH,
+	MATCHED,
+	MATCH_ERROR,
+};
+
+static enum match_result apply_mask_param(const char *cmdline, const char *src_pos,
+					  struct cmdline_mask_param *param,
+					  char **result, int *result_len, char **dst_pos,
+					  const char **next_src_pos)
+{
+	char *key_with_equals;
+	int key_len;
+	const char *value_start, *value_end, *param_end;
+	enum match_result ret;
+
+	if (!param->key)
+		return NO_MATCH;
+
+	key_len = strlen(param->key);
+	if (param->key[key_len - 1] == '=') {
+		key_with_equals = (char *)param->key;
+	} else {
+		key_with_equals = malloc(key_len + 2);
+		if (!key_with_equals) {
+			free(*result);
+			return MATCH_ERROR;
+		}
+		strcpy(key_with_equals, param->key);
+		strcat(key_with_equals, "=");
+	}
+
+	if (strncmp(src_pos, key_with_equals, strlen(key_with_equals)) != 0 ||
+	    (src_pos != cmdline && *(src_pos - 1) != ' ')) {
+		ret = NO_MATCH;
+		goto out;
+	}
+
+	value_start = src_pos + strlen(key_with_equals);
+	value_end = strstr(value_start, " ");
+	if (!value_end)
+		value_end = value_start + strlen(value_start);
+	param_end = value_end;
+
+	if (!param->new_value) {
+		*next_src_pos = (*param_end == ' ') ? param_end + 1 : param_end;
+	} else if (write_replacement(result, result_len, dst_pos,
+				      key_with_equals, param->new_value)) {
+		ret = MATCH_ERROR;
+		goto out;
+	} else {
+		*next_src_pos = param_end;
+	}
+
+	ret = MATCHED;
+
+out:
+	if (key_with_equals != param->key)
+		free(key_with_equals);
+	return ret;
+}
+
+char *mask_cmdline_params(const char *cmdline, struct cmdline_mask_param *params, int count)
+{
+	char *result;
+	const char *src_pos;
+	char *dst_pos;
+	int i, result_len, cmdline_len;
+	bool found_match;
+
+	if (!cmdline || !params || count <= 0)
+		return NULL;
+
+	cmdline_len = strlen(cmdline);
+	result_len = cmdline_len * 2;
+	result = malloc(result_len + 1);
+	if (!result)
+		return NULL;
+
+	src_pos = cmdline;
+	dst_pos = result;
+
+	while (*src_pos) {
+		found_match = false;
+
+		for (i = 0; i < count; i++) {
+			enum match_result mr;
+
+			mr = apply_mask_param(cmdline, src_pos, &params[i],
+					      &result, &result_len, &dst_pos, &src_pos);
+			if (mr == MATCH_ERROR)
+				return NULL;
+			if (mr == MATCHED) {
+				found_match = true;
+				break;
+			}
+		}
+
+		if (!found_match) {
+			if (ensure_capacity(&result, &result_len, &dst_pos, 1))
+				return NULL;
+			*dst_pos++ = *src_pos++;
+		}
+	}
+
+	*dst_pos = '\0';
+	return result;
+}

-- 
2.55.0

