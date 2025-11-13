From: Louis Rannou <louis.rannou@non.se.com>
Date: Thu, 13 Nov 2025 15:46:13 +0100
Subject: [PATCH b4 1/2] Add support for setting a presubject
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251113-sub-v1-1-921bef0da4d2@non.se.com>
References: <20251113-sub-v1-0-921bef0da4d2@non.se.com>
In-Reply-To: <20251113-sub-v1-0-921bef0da4d2@non.se.com>
To: "Kernel.org Tools" <tools@kernel.org>
Cc: Konstantin Ryabitsev <konstantin@linuxfoundation.org>, 
 Louis Rannou <louis.rannou@non.se.com>, pascal.eberhard@se.com, 
 antonin.godard@bootlin.com
X-Mailer: b4 0.15-dev-0f001
X-Developer-Signature: v=1; a=ed25519-sha256; t=1763045178; l=13163;
 i=louis.rannou@non.se.com; s=20250630; h=from:subject:message-id;
 bh=idnIUzlO4VcxjjJ2srtReor3JXt7SlNIvDePCoPPm5E=;
 b=z7nOrPZC0z31HPKEfUJVciGuydvPhNTSRp49fCiA/ywEtn+JJ5+Pd4Bay4RGsD4Jy3fB3MbpK
 YFaciZ4cBp5AZ0fhkzWGnAXEFXptg+orgZ75dY5ZboNPcqPsOFOystm
X-Developer-Key: i=louis.rannou@non.se.com; a=ed25519;
 pk=WWYN5/DFKqyCKdv6oTYNuq0gROqwZVfNfw2OMI3tUlc=
X-Endpoint-Received: by B4 Relay for louis.rannou@non.se.com/20250630 with auth_id=446
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Antonin Godard <antonin.godard@bootlin.com>

Some mailing lists require a prefix to come before the [PATCH] in the
subject of emails, such as OpenEmbedded or libgpiod. The current prefix
mechanism does not allow for that (only after PATCH), and setting the
format.subjectPrefix Git option does not work either.

Add a new configuration option send-presubject as well as a
--set-presubject argument to be able to include anything that should
come before the subject. The logic behind prefixes is not changed and
this new option does not break any existing prefix assignments.

In order not to break the logic in LoreSubject's __init__ function,
which parses the subject line and strips brackets in order to reorganize
the subject line later, the presubject must be enclosed with brackets
too (_check_presubject() is used to ensure that).

Closes: https://bugzilla.kernel.org/show_bug.cgi?id=217642
Signed-off-by: Antonin Godard <antonin.godard@bootlin.com>
---
 src/b4/__init__.py | 27 ++++++++++++++++------
 src/b4/command.py  |  2 ++
 src/b4/ez.py       | 68 ++++++++++++++++++++++++++++++++++++++++++++++--------
 3 files changed, 80 insertions(+), 17 deletions(-)

diff --git a/src/b4/__init__.py b/src/b4/__init__.py
index 7689550..ba76e83 100644
--- a/src/b4/__init__.py
+++ b/src/b4/__init__.py
@@ -2552,7 +2552,7 @@ class LoreSubject:
     counters_inferred: bool
     prefixes: List[str]
 
-    def __init__(self, subject: str) -> None:
+    def __init__(self, subject: str, presubject: str = None) -> None:
         # Subject-based info
         self.reply = False
         self.resend = False
@@ -2592,6 +2592,9 @@ class LoreSubject:
             bracketed = re.sub(r'(patch)(v\d+)', r'\1 \2', bracketed, flags=re.I)
 
             for chunk in bracketed.split():
+                if presubject is not None and chunk in presubject:
+                    continue
+
                 # Remove any trailing commas or semicolons
                 chunk = chunk.strip(',;')
                 if re.search(r'^\d{1,4}/\d{1,4}$', chunk):
@@ -2629,7 +2632,9 @@ class LoreSubject:
 
         return ret
 
-    def get_rebuilt_subject(self, eprefixes: Optional[List[str]] = None) -> str:
+    def get_rebuilt_subject(self, eprefixes: Optional[List[str]] = None,
+                            presubject: str = None) -> str:
+
         exclude = None
         if eprefixes and 'PATCH' in eprefixes:
             exclude = ['patch']
@@ -2645,10 +2650,16 @@ class LoreSubject:
         if self.expected > 1:
             _pfx.append('%s/%s' % (str(self.counter).zfill(len(str(self.expected))), self.expected))
 
+        subject = ""
         if len(_pfx):
-            return '[' + ' '.join(_pfx) + '] ' + self.subject
+            subject = '[' + ' '.join(_pfx) + '] ' + self.subject
         else:
-            return f'[PATCH] {self.subject}'
+            subject = f'[PATCH] {self.subject}'
+
+        if presubject:
+            subject = f'{presubject}{subject}'
+
+        return subject
 
     def get_slug(self, sep: str = '_', with_counter: bool = True) -> str:
         unsafe = self.subject
@@ -3658,7 +3669,8 @@ def git_range_to_patches(gitdir: Optional[str], start: str, end: str,
                          mailfrom: Optional[Tuple[str, str]] = None,
                          extrahdrs: Optional[List[Tuple[str, str]]] = None,
                          ignore_commits: Optional[Set[str]] = None,
-                         limit_committer: Optional[str] = None) -> List[Tuple[str, EmailMessage]]:
+                         limit_committer: Optional[str] = None,
+                         presubject: Optional[str] = None) -> List[Tuple[str, EmailMessage]]:
     gitargs = ['rev-list', '--no-merges', '--reverse']
     if limit_committer:
         gitargs += ['-F', f'--committer={limit_committer}']
@@ -3714,12 +3726,13 @@ def git_range_to_patches(gitdir: Optional[str], start: str, end: str,
         msg.set_charset('utf-8')
         # Clean From to remove any 7bit-safe encoding
         origfrom = LoreMessage.clean_header(msg.get('From'))
-        lsubject = LoreSubject(msg.get('Subject'))
+        lsubject = LoreSubject(msg.get('Subject'), presubject=presubject)
         lsubject.counter = counter + 1
         lsubject.expected = expected
         if revision is not None:
             lsubject.revision = revision
-        subject = lsubject.get_rebuilt_subject(eprefixes=prefixes)
+        subject = lsubject.get_rebuilt_subject(eprefixes=prefixes,
+                                               presubject=presubject)
 
         logger.debug('  %s', subject)
         msg.replace_header('Subject', subject)
diff --git a/src/b4/command.py b/src/b4/command.py
index 0114197..1f8b8f1 100644
--- a/src/b4/command.py
+++ b/src/b4/command.py
@@ -318,6 +318,8 @@ def setup_parser() -> argparse.ArgumentParser:
                          help='Prefixes to include after [PATCH] (e.g.: RFC mydrv)')
     sp_prep.add_argument('--add-prefixes', metavar='PREFIX', nargs='+',
                          help='Additional prefixes to add to those already defined')
+    sp_prep.add_argument('--set-presubject', metavar='PRESUBJECT', type=str, default=None,
+                         help='Prefix to include before [PATCH] (e.g.: [mylist])')
     sp_prep.add_argument('-C', '--no-cache', dest='nocache', action='store_true', default=False,
                          help='Do not use local cache')
     sp_prep.add_argument('--range-diff-opts', default=None, type=str,
diff --git a/src/b4/ez.py b/src/b4/ez.py
index 57bc1ca..0971ae9 100644
--- a/src/b4/ez.py
+++ b/src/b4/ez.py
@@ -584,19 +584,30 @@ def start_new_series(cmdargs: argparse.Namespace) -> None:
         if revision is None:
             revision = 1
         prefixes = list()
+
+        config = b4.get_main_config()
+
         if cmdargs.set_prefixes:
             prefixes = list(cmdargs.set_prefixes)
         else:
-            config = b4.get_main_config()
             _sp = config.get('send-prefixes')
             if _sp and isinstance(_sp, str):
                 prefixes = _sp.split()
 
+        presubject = ''
+        if cmdargs.set_presubject:
+            presubject = cmdargs.set_presubject
+        else:
+            presubject = config.get('send-presubject', '')
+            if presubject and isinstance(presubject, str):
+                _check_presubject(presubject)
+
         tracking = {
             'series': {
                 'revision': revision,
                 'change-id': changeid,
                 'prefixes': prefixes,
+                'presubject': presubject,
             },
         }
         if thread_msgid:
@@ -1458,16 +1469,17 @@ def get_cover_dests(cbody: str) -> Tuple[List[Tuple[str, str]], List[Tuple[str,
 
 
 def add_cover(csubject: b4.LoreSubject, msgid_tpt: str, patches: List[Tuple[str, EmailMessage]],
-              cbody: str, datets: int, thread: bool = True) -> None:
+              cbody: str, datets: int, thread: bool = True, presubject: str = None) -> None:
     fp = patches[0][1]
     cmsg = EmailMessage()
     cmsg.add_header('From', fp['From'])
-    fpls = b4.LoreSubject(fp['Subject'])
+    fpls = b4.LoreSubject(fp['Subject'], presubject=presubject)
 
     csubject.expected = fpls.expected
     csubject.counter = 0
     csubject.revision = fpls.revision
-    cmsg.add_header('Subject', csubject.get_rebuilt_subject(eprefixes=fpls.get_extra_prefixes()))
+    cmsg.add_header('Subject', csubject.get_rebuilt_subject(eprefixes=fpls.get_extra_prefixes(),
+                                                            presubject=presubject))
     cmsg.add_header('Date', email.utils.formatdate(datets, localtime=True))
     cmsg.add_header('Message-Id', msgid_tpt % str(0))
 
@@ -1577,13 +1589,16 @@ def get_prep_branch_as_patches(movefrom: bool = True, thread: bool = True, addtr
     for cprefix in csubject.get_extra_prefixes(exclude=prefixes):
         prefixes.append(cprefix)
 
+    presubject = tracking['series'].get('presubject', list())
+
     patches = b4.git_range_to_patches(None, start_commit, end_commit,
                                       revision=revision,
                                       prefixes=prefixes,
                                       msgid_tpt=msgid_tpt,
                                       seriests=seriests,
                                       mailfrom=mailfrom,
-                                      ignore_commits=ignore_commits)
+                                      ignore_commits=ignore_commits,
+                                      presubject=presubject)
 
     base_commit, _, _, _, shortlog, diffstat = get_series_details(start_commit=start_commit,
                                                                   usebranch=usebranch)
@@ -1649,7 +1664,8 @@ def get_prep_branch_as_patches(movefrom: bool = True, thread: bool = True, addtr
                     continue
                 logger.debug('Checking if we have a sent version')
                 try:
-                    _, _, ppatches = get_sent_tag_as_patches(tagname, revision=revision)
+                    _, _, ppatches = get_sent_tag_as_patches(tagname, revision=revision,
+                                                             presubject=presubject)
                     for psha, ppatch in ppatches:
                         spatches.append(ppatch)
                 except RuntimeError:
@@ -1716,7 +1732,7 @@ def get_prep_branch_as_patches(movefrom: bool = True, thread: bool = True, addtr
     if len(patches) == 1:
         mixin_cover(cbody, patches)
     else:
-        add_cover(csubject, msgid_tpt, patches, cbody, seriests, thread=thread)
+        add_cover(csubject, msgid_tpt, patches, cbody, seriests, thread=thread, presubject=presubject)
 
     if addtracking:
         patches[0][1].add_header('X-B4-Tracking', thdata)
@@ -1745,7 +1761,7 @@ def get_prep_branch_as_patches(movefrom: bool = True, thread: bool = True, addtr
     return alltos, allccs, tag_msg, patches
 
 
-def get_sent_tag_as_patches(tagname: str, revision: int) \
+def get_sent_tag_as_patches(tagname: str, revision: int, presubject: str = None) \
         -> Tuple[List[Tuple[str, str]], List[Tuple[str, str]], List[Tuple[str, EmailMessage]]]:
     cover, base_commit, change_id = get_base_changeid_from_tag(tagname)
 
@@ -1761,7 +1777,8 @@ def get_sent_tag_as_patches(tagname: str, revision: int) \
                                       prefixes=prefixes,
                                       msgid_tpt=msgid_tpt,
                                       seriests=seriests,
-                                      mailfrom=mailfrom)
+                                      mailfrom=mailfrom,
+                                      presubject=presubject)
 
     alltos, allccs, cbody = get_cover_dests(cbody)
     if len(patches) == 1:
@@ -1915,8 +1932,11 @@ def cmd_send(cmdargs: argparse.Namespace) -> None:
                 logger.critical('Could not figure out revision from %s', revstr)
                 sys.exit(1)
 
+        presubject = tracking['series'].get('presubject', None)
+
         try:
-            todests, ccdests, patches = get_sent_tag_as_patches(tagname, revision=revision)
+            todests, ccdests, patches = get_sent_tag_as_patches(tagname, revision=revision, 
+                                                                presubject=presubject)
         except RuntimeError as ex:
             logger.critical('CRITICAL: Failed to convert tag to patches: %s', ex)
             sys.exit(1)
@@ -2939,6 +2959,30 @@ def set_prefixes(prefixes: List[str], additive: bool = False) -> None:
         logger.info('No changes to extra prefixes.')
 
 
+def _check_presubject(presubject: str):
+    if presubject == "":
+        return
+
+    if presubject.startswith("[") and presubject.endswith("]"):
+        return
+
+    raise RuntimeError("The presubject must be enclosed with brackets. E.g: [mylist]")
+
+
+def set_presubject(presubject: str) -> None:
+    cover, tracking = load_cover()
+    old_presubject = tracking['series'].get('presubject', None)
+    tracking['series']['presubject'] = presubject
+    if tracking['series']['presubject'] != old_presubject:
+        store_cover(cover, tracking)
+        if tracking['series']['presubject'] != "":
+            logger.info(f'Updated pre-subject to: {presubject}')
+        else:
+            logger.info('Removed pre-subject.')
+    else:
+        logger.info('No changes to the pre-subject.')
+
+
 def cmd_prep(cmdargs: argparse.Namespace) -> None:
     check_can_gfr()
     status = b4.git_get_repo_status()
@@ -3021,6 +3065,10 @@ def cmd_prep(cmdargs: argparse.Namespace) -> None:
     if cmdargs.add_prefixes:
         set_prefixes(cmdargs.add_prefixes, additive=True)
 
+    if cmdargs.set_presubject is not None:
+        _check_presubject(cmdargs.set_presubject)
+        set_presubject(cmdargs.set_presubject)
+
     if cmdargs.auto_to_cc:
         auto_to_cc()
 

-- 
2.43.0

