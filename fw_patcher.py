import os
import shutil
import stat
import subprocess


class ApkFile:
    def __init__(self, file, output):
        self.file = file
        self.output = output

def framework_patcher(framework: ApkFile, services: ApkFile, miui_framework: ApkFile, miui_services: ApkFile):
    repo_path = 'FrameworkPatcher'
    if os.path.exists(repo_path):
        # Hoàn tác các thay đổi và kéo cập nhật từ kho lưu trữ
        subprocess.run(['git', 'reset', '--hard'], cwd=repo_path, check=True)
        subprocess.run(['git', 'clean', '-fdx'], cwd=repo_path, check=True)
        subprocess.run(['git', 'pull'], cwd=repo_path, check=True)
    else:
        subprocess.run(
            f'git clone --depth 1 https://github.com/Jefino9488/FrameworkPatcher.git', shell=True, check=True)
    smali_info = [
        {'apk_name': f'{os.path.basename(framework.file)}', 'src': 'classes', 'dst': 'classes'},
        {'apk_name': f'{os.path.basename(framework.file)}', 'src': 'classes2', 'dst': 'classes2'},
        {'apk_name': f'{os.path.basename(framework.file)}', 'src': 'classes3', 'dst': 'classes3'},
        {'apk_name': f'{os.path.basename(framework.file)}', 'src': 'classes4', 'dst': 'classes4'},
        {'apk_name': f'{os.path.basename(framework.file)}', 'src': 'classes5', 'dst': 'classes5'},
        {'apk_name': f'{os.path.basename(services.file)}', 'src': 'classes', 'dst': 'services_classes'},
        {'apk_name': f'{os.path.basename(services.file)}', 'src': 'classes2', 'dst': 'services_classes2'},
        {'apk_name': f'{os.path.basename(services.file)}', 'src': 'classes3', 'dst': 'services_classes3'},
        {'apk_name': f'{os.path.basename(miui_framework.file)}', 'src': 'classes', 'dst': 'miui_framework_classes'},
        {'apk_name': f'{os.path.basename(miui_services.file)}', 'src': 'classes', 'dst': 'miui_services_classes'}
    ]

    def copy_directory(apk: ApkFile, reverse=False):
        for info in smali_info:
            apk_name = os.path.basename(apk.file)
            if apk_name == info['apk_name']:
                src_dir = info['src']
                dst_dir = info['dst']
                if reverse:
                    dst_path = os.path.join(apk.output, src_dir)
                    src_path = os.path.join('FrameworkPatcher', dst_dir)
                else:
                    src_path = os.path.join(apk.output, src_dir)
                    dst_path = os.path.join('FrameworkPatcher', dst_dir)

                shutil.rmtree(dst_path, ignore_errors=True)
                shutil.move(src_path, dst_path)

    copy_directory(framework)
    copy_directory(services)
    copy_directory(miui_framework)
    copy_directory(miui_services)

    original_workdir = os.getcwd()
    os.chdir('FrameworkPatcher')
    subprocess.run(f'python framework_patch.py', check=True)
    subprocess.run(f'python miui-service_Patch.py', check=True)
    subprocess.run(f'python miui-framework_patch.py', check=True)
    subprocess.run(f'python miui-service_Patch.py', check=True)

    os.chdir(original_workdir)
    shutil.copytree('FrameworkPatcher/magisk_module/system', 'extracted', dirs_exist_ok=True)

    copy_directory(framework, True)
    copy_directory(services, True)
    copy_directory(miui_framework, True)
    copy_directory(miui_services, True)


def main():
    os.chdir('out')
    framework = ApkFile('tmp/framework/framework.jar', 'tmp/framework')
    services = ApkFile('tmp/services/services.jar', 'tmp/services')
    miui_framework = ApkFile('tmp/miui-framework/miui-framework.jar', 'tmp/miui-framework')
    miui_services = ApkFile('tmp/miui-services/miui-services.jar', 'tmp/miui-services')
    framework_patcher(framework, services, miui_framework, miui_services)


if __name__ == '__main__':
    main()
