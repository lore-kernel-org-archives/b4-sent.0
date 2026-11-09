From: Patrick Vogelaar <patrick.vogelaar@belden.com>
Date: Mon, 09 Nov 2026 08:46:39 +0100
Subject: [PATCH 3/3] toaster: take build times from the events
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261109-toaster-projects-nobuild-v1-3-7e65cadc2d39@belden.com>
References: <20261109-toaster-projects-nobuild-v1-0-7e65cadc2d39@belden.com>
In-Reply-To: <20261109-toaster-projects-nobuild-v1-0-7e65cadc2d39@belden.com>
To: bitbake-devel@lists.openembedded.org
Cc: Patrick Vogelaar <patrick.vogelaar@belden.com>, 
 patrick.vogelaar.dev@mailbox.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794210409; l=8373;
 i=patrick.vogelaar@belden.com; s=20240201; h=from:subject:message-id;
 bh=1+rb0U/ViAKhPSGmYnDFoRt6HqkQtQj6qm/fr/2doic=;
 b=W0vruMpuTECAFtgxqsp3gypMkCDi7cHRBOJeuAOnXx7XopS5jxY1Cl1LnqgTGm1dbYAGBo5jM
 tZZnJHFGz2UCi6DtVsXPDmhASYJc+dQZ/IcPLhhLn83MR+hyj+qV4z5
X-Developer-Key: i=patrick.vogelaar@belden.com; a=ed25519;
 pk=w0QU8RmOR3hQv1DxMcz6KmySeE8yqbvO0xC1ZSSUNqY=
X-Endpoint-Received: by B4 Relay for patrick.vogelaar@belden.com/20240201 with auth_id=125
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Toaster sets the start and end time of a build to the time it processes
the build's first and last event. For live builds this is the build
time, but an event log replayed with toaster-eventreplay gets the time
of the replay, so all replayed builds show when they were imported and
how long the import took.

Remember the time of the latest event that carries one (log records and
task events) and use it for the start and end of the build. Live builds
get the time of the latest log or task event, which is at most seconds
earlier than before. If no such event has been seen yet, the current
time is used as before. Task times already come from the build
statistics.

Add tests/buildinfohelper/test_build_time.py.

AI-Generated: Uses Kiro (claude-opus-5.5)
Signed-off-by: Patrick Vogelaar <patrick.vogelaar@belden.com>
---
 lib/bb/ui/buildinfohelper.py                       | 32 ++++++++---
 lib/bb/ui/toasterui.py                             |  1 +
 .../tests/buildinfohelper/test_build_time.py       | 62 ++++++++++++++++++++++
 3 files changed, 88 insertions(+), 7 deletions(-)

diff --git a/lib/bb/ui/buildinfohelper.py b/lib/bb/ui/buildinfohelper.py
index 787cab952..7cc8229d5 100644
--- a/lib/bb/ui/buildinfohelper.py
+++ b/lib/bb/ui/buildinfohelper.py
@@ -43,7 +43,7 @@ from bb.msg import BBLogFormatter as formatter
 from django.db import models
 from pprint import pformat
 import logging
-from datetime import datetime, timedelta
+from datetime import datetime, timedelta, timezone as dt_timezone
 
 from django.db import transaction
 
@@ -143,10 +143,12 @@ class ORMWrapper(object):
     # pylint: disable=bad-continuation
     # we do not follow the python conventions for continuation indentation due to long lines here
 
-    def get_or_create_build_object(self, brbe, project_name=None):
+    def get_or_create_build_object(self, brbe, project_name=None,
+                                   started_on=None):
         """
         project_name: for command line builds, the project to put the build
         into (created if needed); None or empty for the default project
+        started_on: start time of a new Build object; defaults to now
         """
         project_name = project_name.strip() if project_name else None
         prj = None
@@ -175,7 +177,7 @@ class ORMWrapper(object):
             build.save()
         else:
             # create new Build object
-            now = timezone.now()
+            now = started_on or timezone.now()
             build = Build.objects.create(
                 project=prj,
                 started_on=now,
@@ -217,7 +219,8 @@ class ORMWrapper(object):
             result.append(obj)
         return result
 
-    def update_build_stats_and_outcome(self, build, errors, warnings, taskfailures):
+    def update_build_stats_and_outcome(self, build, errors, warnings, taskfailures,
+                                       completed_on=None):
         assert isinstance(build,Build)
         assert isinstance(errors, int)
         assert isinstance(warnings, int)
@@ -235,7 +238,7 @@ class ORMWrapper(object):
         if errors or taskfailures:
             outcome = Build.FAILED
 
-        build.completed_on = timezone.now()
+        build.completed_on = completed_on or timezone.now()
         build.outcome = outcome
         build.save()
 
@@ -922,6 +925,10 @@ class BuildInfoHelper(object):
 
         self.project = None
 
+        # time of the latest event that has one; event logs can be replayed
+        # long after the build, so build times are taken from the events
+        self.event_time = None
+
         logger.debug("buildinfohelper: Build info helper inited %s" % vars(self))
 
 
@@ -940,7 +947,8 @@ class BuildInfoHelper(object):
             if self.brbe is None:
                 project_name, _ = self.server.runCommand(["getVariable", "TOASTER_PROJECT"])
             self.internal_state['build'] = \
-                self.orm_wrapper.get_or_create_build_object(self.brbe, project_name)
+                self.orm_wrapper.get_or_create_build_object(
+                    self.brbe, project_name, self.event_time)
 
         build = self.internal_state['build']
 
@@ -1103,6 +1111,15 @@ class BuildInfoHelper(object):
             except NotExisting as nee:
                 logger.warning("buildinfohelper: cannot identify layer exception:%s ", nee)
 
+    def update_event_time(self, event):
+        """Remember the time of events that carry one"""
+        if isinstance(event, logging.LogRecord):
+            secs = event.created
+        else:
+            secs = getattr(event, 'time', None)
+        if isinstance(secs, (int, float)):
+            self.event_time = datetime.fromtimestamp(secs, dt_timezone.utc)
+
     def store_started_build(self):
         self._ensure_build()
 
@@ -1210,7 +1227,8 @@ class BuildInfoHelper(object):
     def update_build_information(self, event, errors, warnings, taskfailures):
         self._ensure_build()
         self.orm_wrapper.update_build_stats_and_outcome(
-            self.internal_state['build'], errors, warnings, taskfailures)
+            self.internal_state['build'], errors, warnings, taskfailures,
+            self.event_time)
 
     def store_started_task(self, event):
         assert isinstance(event, (bb.runqueue.sceneQueueTaskStarted, bb.runqueue.runQueueTaskStarted, bb.runqueue.runQueueTaskSkipped))
diff --git a/lib/bb/ui/toasterui.py b/lib/bb/ui/toasterui.py
index 6bd21f184..971d06c03 100644
--- a/lib/bb/ui/toasterui.py
+++ b/lib/bb/ui/toasterui.py
@@ -224,6 +224,7 @@ def main(server, eventHandler, params):
                 continue
 
             helper.eventHandler(event)
+            buildinfohelper.update_event_time(event)
 
             # pylint: disable=protected-access
             # the code will look into the protected variables of the event; no easy way around this
diff --git a/lib/toaster/tests/buildinfohelper/test_build_time.py b/lib/toaster/tests/buildinfohelper/test_build_time.py
new file mode 100644
index 000000000..363eeeee3
--- /dev/null
+++ b/lib/toaster/tests/buildinfohelper/test_build_time.py
@@ -0,0 +1,62 @@
+#! /usr/bin/env python3
+#
+# BitBake Toaster Implementation
+#
+# SPDX-License-Identifier: GPL-2.0-only
+#
+
+"""Build start and end times are taken from the events."""
+
+import logging
+from datetime import datetime, timezone
+
+import bb.build
+import bb.data
+import bb.event
+from django.test import TransactionTestCase
+
+from bb.ui.buildinfohelper import BuildInfoHelper
+from bb.ui.eventreplay import EventPlayer
+from orm.models import Build
+
+START = 1700000000.5
+END = 1700001500.25
+
+
+def utc(secs):
+    return datetime.fromtimestamp(secs, timezone.utc)
+
+
+class BuildTimeTests(TransactionTestCase):
+    """A replayed event log keeps the times of the original build"""
+
+    def setUp(self):
+        variables = {name: {'v': name.lower()} for name in
+                     ('BUILDNAME', 'MACHINE', 'DISTRO', 'DISTRO_VERSION',
+                      'BB_VERSION', 'TMPDIR')}
+        server = EventPlayer(None, variables)
+        self.helper = BuildInfoHelper(server)
+
+    def test_times_from_events(self):
+        record = logging.LogRecord('BitBake', logging.INFO, '', 0, 'msg',
+                                   None, None)
+        record.created = START
+        self.helper.update_event_time(record)
+        self.helper.store_started_build()
+
+        task = bb.build.TaskSucceeded('do_build', 'test.bb', None,
+                                      bb.data.init())
+        task.time = END
+        self.helper.update_event_time(task)
+        self.helper.update_build_information(None, 0, 0, [])
+
+        build = Build.objects.get()
+        self.assertEqual(build.started_on, utc(START))
+        self.assertEqual(build.completed_on, utc(END))
+        self.assertEqual(build.outcome, Build.SUCCEEDED)
+
+    def test_events_without_time_keep_the_clock(self):
+        before = datetime.now(timezone.utc)
+        self.helper.update_event_time(bb.event.BuildStarted('build', []))
+        self.helper.store_started_build()
+        self.assertGreaterEqual(Build.objects.get().started_on, before)

-- 
2.43.0

