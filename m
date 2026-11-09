From: Patrick Vogelaar <patrick.vogelaar@belden.com>
Date: Mon, 09 Nov 2026 08:46:38 +0100
Subject: [PATCH 2/3] toaster: group command line builds by TOASTER_PROJECT
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261109-toaster-projects-nobuild-v1-2-7e65cadc2d39@belden.com>
References: <20261109-toaster-projects-nobuild-v1-0-7e65cadc2d39@belden.com>
In-Reply-To: <20261109-toaster-projects-nobuild-v1-0-7e65cadc2d39@belden.com>
To: bitbake-devel@lists.openembedded.org
Cc: Patrick Vogelaar <patrick.vogelaar@belden.com>, 
 patrick.vogelaar.dev@mailbox.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794210409; l=22032;
 i=patrick.vogelaar@belden.com; s=20240201; h=from:subject:message-id;
 bh=AdxjS4EVRKRjs3G6na6OqKjMdA06zozH973H9cq7gvs=;
 b=7f0oO9Y093lcVlArHl+KAt9wlkfppq83bVzrtesaI7Ls7bb6L9lrd/BIyHAQfvbrRL+6CWaRR
 IL/iWJjrSghAaZ7uhYqc3v74xgcv9iytQUz0hYFRVRQKz/0ZVxdeMim
X-Developer-Key: i=patrick.vogelaar@belden.com; a=ed25519;
 pk=w0QU8RmOR3hQv1DxMcz6KmySeE8yqbvO0xC1ZSSUNqY=
X-Endpoint-Received: by B4 Relay for patrick.vogelaar@belden.com/20240201 with auth_id=125
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

All command line builds, live ones and replayed event logs, end up in
the default "Command line builds" project. When builds come from
several branches or CI systems, e.g. a CI that uploads event logs to a
shared Toaster instance, they cannot be told apart by project.

If TOASTER_PROJECT is set, put a command line build into the project of
that name and create a normal project, including its default settings,
if it does not exist yet. Empty values keep the existing default
project behavior. The variable is read from the datastore so that it is
recorded in event logs; bin/toaster adds it to
BB_ENV_PASSTHROUGH_ADDITIONS like TOASTER_DIR.

Determine whether a build is a command line build from the absence of a
BuildRequest, rather than from the default project. This keeps layers
and recipes scoped correctly and avoids offering Rebuild or Cancel for
command line builds in named projects. Projects created this way have
no release, so in build mode they are shown like the default project,
without configuration pages, build form or custom image actions.
Managed builds are unchanged.

Document TOASTER_PROJECT in the BitBake variable reference. Add the
tests/buildinfohelper test package and include it in tox, and give the
project in tests/views/test_nobuild.py a release. Update the existing
browser test to model a managed build with its BuildRequest.

AI-Generated: Uses Kiro (claude-opus-5.5)
Signed-off-by: Patrick Vogelaar <patrick.vogelaar@belden.com>
---
 bin/toaster                                        |   2 +-
 .../bitbake-user-manual-ref-variables.rst          |  13 ++
 lib/bb/ui/buildinfohelper.py                       |  26 +++-
 lib/toaster/tests/browser/test_all_builds_page.py  |   2 +
 lib/toaster/tests/buildinfohelper/__init__.py      |   0
 .../tests/buildinfohelper/test_cli_project.py      | 131 +++++++++++++++++++++
 lib/toaster/tests/views/test_nobuild.py            |   8 +-
 .../toastergui/templates/basebuildpage.html        |   5 +-
 lib/toaster/toastergui/templates/mrb_section.html  |   4 +-
 .../toastergui/templates/projecttopbar.html        |   2 +-
 .../toastergui/templatetags/project_url_tag.py     |   7 +-
 lib/toaster/toastergui/views.py                    |   7 ++
 lib/toaster/toastergui/widgets.py                  |   2 +-
 lib/toaster/tox.ini                                |   3 +-
 14 files changed, 194 insertions(+), 18 deletions(-)

diff --git a/bin/toaster b/bin/toaster
index 16a64bab6..79b3cdbda 100755
--- a/bin/toaster
+++ b/bin/toaster
@@ -263,7 +263,7 @@ fi
 # 4) pid's we need to clean up on exit/shutdown
 # By default we move this all into the Toaster's parent build directory
 export TOASTER_DIR=$BUILDDIR
-export BB_ENV_PASSTHROUGH_ADDITIONS="$BB_ENV_PASSTHROUGH_ADDITIONS TOASTER_DIR"
+export BB_ENV_PASSTHROUGH_ADDITIONS="$BB_ENV_PASSTHROUGH_ADDITIONS TOASTER_DIR TOASTER_PROJECT"
 
 # Determine the action. If specified by arguments, fine, if not, toggle it
 if [ "$CMD" = "start" ] ; then
diff --git a/doc/bitbake-user-manual/bitbake-user-manual-ref-variables.rst b/doc/bitbake-user-manual/bitbake-user-manual-ref-variables.rst
index fd75275bb..41e8ec74d 100644
--- a/doc/bitbake-user-manual/bitbake-user-manual-ref-variables.rst
+++ b/doc/bitbake-user-manual/bitbake-user-manual-ref-variables.rst
@@ -1922,6 +1922,19 @@ overview of their function and contents.
       consist mostly of task logs and scripts, when building a particular
       recipe.
 
+   :term:`TOASTER_PROJECT`
+      Specifies the name of the Toaster project in which to store a build
+      started from the command line. If the project does not exist, Toaster
+      creates it. If this variable is not set, Toaster stores the build in the
+      default "Command line builds" project. This variable has no effect on
+      builds started from the Toaster web interface.
+
+      Toaster reads this variable from the BitBake datastore, so it is also
+      recorded in event logs. You can set it in a configuration file such as
+      ``local.conf``. To set it from the environment, the variable must be
+      listed in :term:`BB_ENV_PASSTHROUGH_ADDITIONS`, which the ``toaster``
+      start script does for you.
+
    :term:`TOPDIR`
       Points to the build directory. BitBake automatically sets this
       variable.
diff --git a/lib/bb/ui/buildinfohelper.py b/lib/bb/ui/buildinfohelper.py
index 4ee45d67a..787cab952 100644
--- a/lib/bb/ui/buildinfohelper.py
+++ b/lib/bb/ui/buildinfohelper.py
@@ -143,7 +143,12 @@ class ORMWrapper(object):
     # pylint: disable=bad-continuation
     # we do not follow the python conventions for continuation indentation due to long lines here
 
-    def get_or_create_build_object(self, brbe):
+    def get_or_create_build_object(self, brbe, project_name=None):
+        """
+        project_name: for command line builds, the project to put the build
+        into (created if needed); None or empty for the default project
+        """
+        project_name = project_name.strip() if project_name else None
         prj = None
         buildrequest = None
         if brbe is not None:
@@ -152,6 +157,12 @@ class ORMWrapper(object):
             br, _ = brbe.split(":")
             buildrequest = BuildRequest.objects.get(pk=br)
             prj = buildrequest.project
+        elif project_name:
+            # CLI build with TOASTER_PROJECT set
+            prj = Project.objects.filter(name=project_name).first()
+            if prj is None:
+                prj = Project.objects.create_project(project_name, None)
+            logger.debug("buildinfohelper: project is %s" % prj)
         else:
             # CLI build
             prj = Project.objects.get_or_create_default_project()
@@ -348,8 +359,7 @@ class ORMWrapper(object):
         # and therefore we return the 'real' recipe rather than the build
         # history copy of the recipe.
         if  recipe_information['layer_version'].build is not None and \
-            recipe_information['layer_version'].build.project == \
-                Project.objects.get_or_create_default_project():
+            recipe_information['layer_version'].build.get_buildrequest() is None:
             return recipe
 
         if built_recipe is None:
@@ -394,7 +404,7 @@ class ORMWrapper(object):
         # If we're doing a command line build then associate this new layer with the
         # project to avoid it 'contaminating' toaster data
         project = None
-        if build_obj.project == Project.objects.get_or_create_default_project():
+        if build_obj.get_buildrequest() is None:
             project = build_obj.project
 
         layer_version_object, _ = Layer_Version.objects.get_or_create(
@@ -924,9 +934,13 @@ class BuildInfoHelper(object):
         data on the bitbake server
         """
         if not 'build' in self.internal_state or not self.internal_state['build']:
-            # create the Build object
+            # create the Build object; command line builds go into the
+            # project named by TOASTER_PROJECT, if set
+            project_name = None
+            if self.brbe is None:
+                project_name, _ = self.server.runCommand(["getVariable", "TOASTER_PROJECT"])
             self.internal_state['build'] = \
-                self.orm_wrapper.get_or_create_build_object(self.brbe)
+                self.orm_wrapper.get_or_create_build_object(self.brbe, project_name)
 
         build = self.internal_state['build']
 
diff --git a/lib/toaster/tests/browser/test_all_builds_page.py b/lib/toaster/tests/browser/test_all_builds_page.py
index 9ab81fb11..baf65ebc3 100644
--- a/lib/toaster/tests/browser/test_all_builds_page.py
+++ b/lib/toaster/tests/browser/test_all_builds_page.py
@@ -192,6 +192,8 @@ class TestAllBuildsPage(SeleniumTestCase):
         but should be shown for other builds
         """
         build1 = Build.objects.create(**self.project1_build_success)
+        BuildRequest.objects.create(project=self.project1, build=build1,
+                                    state=BuildRequest.REQ_COMPLETED)
         default_build = Build.objects.create(
             **self.default_project_build_success)
 
diff --git a/lib/toaster/tests/buildinfohelper/__init__.py b/lib/toaster/tests/buildinfohelper/__init__.py
new file mode 100644
index 000000000..e69de29bb
diff --git a/lib/toaster/tests/buildinfohelper/test_cli_project.py b/lib/toaster/tests/buildinfohelper/test_cli_project.py
new file mode 100644
index 000000000..edc22e121
--- /dev/null
+++ b/lib/toaster/tests/buildinfohelper/test_cli_project.py
@@ -0,0 +1,131 @@
+#! /usr/bin/env python3
+#
+# BitBake Toaster Implementation
+#
+# SPDX-License-Identifier: GPL-2.0-only
+#
+
+"""Project of command line builds (TOASTER_PROJECT)."""
+
+from unittest import mock
+
+from django.template import Context, Template
+from django.test import TestCase
+from django.urls import reverse
+from django.utils import timezone
+
+from bb.ui.buildinfohelper import BuildInfoHelper, ORMWrapper
+from bldcontrol.models import BuildRequest
+from orm.models import Build, Project, Layer, Layer_Version, ToasterSetting
+
+
+class CommandLineBuildProjectTests(TestCase):
+
+    def setUp(self):
+        self.orm = ORMWrapper()
+
+    def test_default_project_without_name(self):
+        for name in (None, '', '   '):
+            build = self.orm.get_or_create_build_object(None, name)
+            self.assertTrue(build.project.is_default)
+
+    def test_named_project_is_created_once(self):
+        ToasterSetting.objects.create(name='DEFCONF_MACHINE', value='qemux86-64')
+        first = self.orm.get_or_create_build_object(None, 'poky: master')
+        second = self.orm.get_or_create_build_object(None, 'poky: master')
+        self.assertEqual(first.project.name, 'poky: master')
+        self.assertFalse(first.project.is_default)
+        self.assertEqual(first.project, second.project)
+        self.assertEqual(first.project.get_variable('MACHINE'), 'qemux86-64')
+        self.assertEqual(Project.objects.filter(name='poky: master').count(), 1)
+
+    def test_existing_project_is_used(self):
+        project = Project.objects.create(name='existing')
+        build = self.orm.get_or_create_build_object(None, 'existing')
+        self.assertEqual(build.project, project)
+
+    def test_layers_stay_with_the_project(self):
+        # like for the default project, layers of a command line build are
+        # associated with its project and not added to the shared layer data
+        build = self.orm.get_or_create_build_object(None, 'poky: master')
+        layer_version = self.orm.get_update_layer_version_object(
+            build, Layer.objects.create(name='meta-test'),
+            {'branch': 'master', 'commit': 'abc', 'priority': 6,
+             'local_path': '/srv/meta-test'})
+        self.assertEqual(layer_version.project, build.project)
+        self.assertEqual(Layer_Version.objects.get(pk=layer_version.pk).build, build)
+
+
+class FakeServer:
+
+    values = {
+        'TMPDIR': '/tmp',
+        'TOASTER_PROJECT': 'poky: master',
+        'BUILDNAME': 'test-build',
+        'MACHINE': 'qemux86-64',
+        'DISTRO': 'poky',
+        'DISTRO_VERSION': 'test',
+        'BB_VERSION': 'test',
+    }
+
+    def runCommand(self, command):
+        return self.values.get(command[1]), None
+
+
+class BuildInfoHelperProjectTests(TestCase):
+
+    def test_toaster_project_is_read_from_bitbake(self):
+        helper = BuildInfoHelper(FakeServer())
+        helper.store_started_build()
+        build = helper.internal_state['build']
+        self.assertEqual(build.project.name, 'poky: master')
+        self.assertEqual(build.machine, 'qemux86-64')
+
+
+class CommandLineBuildWidgetTests(TestCase):
+
+    def test_only_managed_build_can_be_rebuilt(self):
+        project = Project.objects.create(name='poky: master')
+        now = timezone.now()
+        cli_build = Build.objects.create(project=project, started_on=now,
+                                         completed_on=now,
+                                         outcome=Build.SUCCEEDED)
+        managed_build = Build.objects.create(project=project, started_on=now,
+                                             completed_on=now,
+                                             outcome=Build.SUCCEEDED)
+        BuildRequest.objects.create(project=project, build=managed_build,
+                                    state=BuildRequest.REQ_COMPLETED)
+
+        response = self.client.get(reverse('most_recent_builds'))
+        self.assertEqual(response.status_code, 200)
+        builds = {build['id']: build for build in response.json()}
+        self.assertTrue(builds[cli_build.id]['is_cli_build'])
+        self.assertFalse(builds[managed_build.id]['is_cli_build'])
+
+
+@mock.patch('toastergui.views.project_enable', True)
+@mock.patch.dict('os.environ', {'TOASTER_BUILDSERVER': '1'})
+class CommandLineProjectPagesTests(TestCase):
+    """In build mode, a project without a release only holds command line
+    builds and cannot be configured or built from Toaster"""
+
+    def setUp(self):
+        self.project = ORMWrapper().get_or_create_build_object(
+            None, 'poky: master').project
+        self.builds_url = reverse('projectbuilds', args=(self.project.id,))
+
+    def test_configuration_pages_redirect_to_builds(self):
+        for name in ('project', 'projectconf'):
+            response = self.client.get(reverse(name, args=(self.project.id,)))
+            self.assertRedirects(response, self.builds_url,
+                                 fetch_redirect_response=False)
+
+    def test_builds_page_has_no_project_topbar(self):
+        response = self.client.get(self.builds_url)
+        self.assertEqual(response.status_code, 200)
+        self.assertNotContains(response, 'id="project-topbar"')
+
+    def test_project_url_is_builds_page(self):
+        template = Template('{% load project_url_tag %}{% project_url p %}')
+        self.assertEqual(template.render(Context({'p': self.project})),
+                         self.builds_url)
diff --git a/lib/toaster/tests/views/test_nobuild.py b/lib/toaster/tests/views/test_nobuild.py
index a8ee82179..4bcb9853e 100644
--- a/lib/toaster/tests/views/test_nobuild.py
+++ b/lib/toaster/tests/views/test_nobuild.py
@@ -15,12 +15,18 @@ from django.urls import reverse
 from django.utils import timezone
 
 from orm.models import Project, Build, Variable, Layer, Layer_Version, Recipe
+from orm.models import BitbakeVersion, Release
 
 
 class ProjectPagesBase(TestCase):
 
     def setUp(self):
-        self.project = Project.objects.create(name="test project")
+        bbv = BitbakeVersion.objects.create(name='bbv', giturl='/tmp/',
+                                            branch='master', dirpath='')
+        release = Release.objects.create(name='release',
+                                         bitbake_version=bbv)
+        self.project = Project.objects.create(name="test project",
+                                              release=release)
         self.builds_url = reverse('projectbuilds', args=(self.project.id,))
         self.config_url = reverse('project', args=(self.project.id,))
 
diff --git a/lib/toaster/toastergui/templates/basebuildpage.html b/lib/toaster/toastergui/templates/basebuildpage.html
index b7982dd2c..db3e3494a 100644
--- a/lib/toaster/toastergui/templates/basebuildpage.html
+++ b/lib/toaster/toastergui/templates/basebuildpage.html
@@ -148,8 +148,9 @@
             </a>
           </li>
 
-          <!-- custom images can only be built in build mode -->
-          {% if project_enable %}
+          <!-- custom images can only be built in build mode, in a project
+               with a release -->
+          {% if project_enable and build.project.release %}
           {% with build.get_custom_image_recipes as custom_image_recipes %}
             {% if custom_image_recipes.count > 0 %}
               <!-- edit custom image built during this build -->
diff --git a/lib/toaster/toastergui/templates/mrb_section.html b/lib/toaster/toastergui/templates/mrb_section.html
index 9fc7dfaee..91c3e6f5b 100644
--- a/lib/toaster/toastergui/templates/mrb_section.html
+++ b/lib/toaster/toastergui/templates/mrb_section.html
@@ -255,7 +255,7 @@
 
 <!-- rebuild button or no rebuild icon -->
 <script id="rebuild-template" type="text/x-jsrender">
-  <%if is_default_project_build%>
+  <%if is_cli_build%>
     <!-- no rebuild info icon -->
     <span class="pull-right glyphicon glyphicon-question-sign get-help <%if state == 'Succeeded'%>get-help-green<%else state == 'Failed'%>get-help-red<%else%>get-help-blue<%/if%>"
     title="Builds in this project cannot be started from Toaster: they are started from the command line">
@@ -272,7 +272,7 @@
 
 <!-- cancel button or no cancel icon -->
 <script id="cancel-template" type="text/x-jsrender">
-  <%if is_default_project_build%>
+  <%if is_cli_build%>
     <!-- no cancel icon -->
     <span class="glyphicon glyphicon-question-sign get-help get-help-blue pull-right" title="Builds in this project cannot be cancelled from Toaster: they can only be cancelled from the command line"></span>
   <%else%>
diff --git a/lib/toaster/toastergui/templates/projecttopbar.html b/lib/toaster/toastergui/templates/projecttopbar.html
index 5673f5c13..e2055cb9b 100644
--- a/lib/toaster/toastergui/templates/projecttopbar.html
+++ b/lib/toaster/toastergui/templates/projecttopbar.html
@@ -41,7 +41,7 @@
     </form>
   </div>
 
-  {% if project_enable and not project.is_default %}
+  {% if project_enable and not project.is_default and project.release %}
   <div id="project-topbar">
     <ul class="nav nav-tabs">
       <li id="topbar-configuration-tab">
diff --git a/lib/toaster/toastergui/templatetags/project_url_tag.py b/lib/toaster/toastergui/templatetags/project_url_tag.py
index 7554f2a28..d9cebda1f 100644
--- a/lib/toaster/toastergui/templatetags/project_url_tag.py
+++ b/lib/toaster/toastergui/templatetags/project_url_tag.py
@@ -12,8 +12,9 @@ register = template.Library()
 def project_url(parser, token):
     """
     Create a URL for a project's main page;
-    for non-default projects in build mode, this is the configuration page;
-    for the default project, or without build mode, this is the project
+    for non-default projects with a release in build mode, this is the
+    configuration page; for the default project, projects without a release
+    (e.g. from TOASTER_PROJECT), or without build mode, this is the project
     builds page
     """
     try:
@@ -32,7 +33,7 @@ class ProjectUrlNode(template.Node):
         try:
             project = self.project.resolve(context)
             build_mode = os.environ.get('TOASTER_BUILDSERVER') == '1'
-            if project.is_default or not build_mode:
+            if project.is_default or not build_mode or project.release is None:
                 return reverse('projectbuilds', args=(project.id,))
             else:
                 return reverse('project', args=(project.id,))
diff --git a/lib/toaster/toastergui/views.py b/lib/toaster/toastergui/views.py
index c43492af8..1cdf47cc5 100644
--- a/lib/toaster/toastergui/views.py
+++ b/lib/toaster/toastergui/views.py
@@ -1535,6 +1535,11 @@ if True:
                 return redirect("%s?%s" % (reverse(project_specific, args=(project.pk,)),params))
             else:
                 return redirect(reverse(project_specific, args=(project.pk,)))
+        # projects without a release (e.g. from TOASTER_PROJECT) only
+        # hold command line builds
+        if project.release is None:
+            return redirect('projectbuilds', pid=pid)
+
         context = {"project": project}
         return toaster_render(request, "project.html", context)
 
@@ -1826,6 +1831,8 @@ if True:
             prj = Project.objects.get(id = pid)
         except Project.DoesNotExist:
             return HttpResponseNotFound("<h1>Project id " + pid + " is unavailable</h1>")
+        if prj.release is None:
+            return redirect('projectbuilds', pid=pid)
 
         # remove disallowed and externally managed varaibles from this list
         vars_managed,vars_fstypes,vars_disallowed = get_project_configvars_context()
diff --git a/lib/toaster/toastergui/widgets.py b/lib/toaster/toastergui/widgets.py
index b32abf40b..eb2050117 100644
--- a/lib/toaster/toastergui/widgets.py
+++ b/lib/toaster/toastergui/widgets.py
@@ -544,7 +544,7 @@ class MostRecentBuildsView(View):
             build['rebuild_url'] = rebuild_url
             build['cancel_url'] = cancel_url
 
-            build['is_default_project_build'] = build_obj.project.is_default
+            build['is_cli_build'] = build_obj.get_buildrequest() is None
 
             build['build_targets_json'] = \
                 template_json(get_tasks(build_obj.target_set.all()))
diff --git a/lib/toaster/tox.ini b/lib/toaster/tox.ini
index 1516a527a..6ae38de3c 100644
--- a/lib/toaster/tox.ini
+++ b/lib/toaster/tox.ini
@@ -13,9 +13,10 @@ setenv =
     DJANGO_SETTINGS_MODULE=toastermain.settings_test
     TOASTER_BUILDSERVER=1
     BUILDDIR = {env:BUILDDIR}
+    PYTHONPATH = {toxinidir}/..
     EVENTREPLAY_DIR = {env:EVENTREPLAY_DIR:BUILDDIR}
 commands =
-    python3 {toxinidir}/manage.py test tests.db tests.commands tests.builds tests.browser tests.functional tests.views
+    python3 {toxinidir}/manage.py test tests.db tests.commands tests.builds tests.browser tests.functional tests.views tests.buildinfohelper
 deps = 
     -r {toxinidir}/../../toaster-requirements.txt
     -r {toxinidir}/tests/toaster-tests-requirements.txt

-- 
2.43.0

