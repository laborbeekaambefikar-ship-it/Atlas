from setuptools import setup

package_name = 'atlas_mission_manager'

setup(
    name=package_name,
    version='1.0.0',
    packages=[
        package_name,
        package_name + '.gui',
    ],
    data_files=[
        ('share/ament_index/resource_index/packages',
         ['resource/' + package_name]),
        ('share/' + package_name, ['package.xml']),
    ],
    install_requires=['setuptools'],
    zip_safe=True,
    maintainer='atlas',
    maintainer_email='atlas@dev.local',
    description='ATLAS mission FSM, velocity arbiter, CLI sender, and GUI.',
    license='MIT',
    entry_points={
        'console_scripts': [
            'mission_node = atlas_mission_manager.mission_node:main',
            'send_mission = atlas_mission_manager.send_mission:main',
            'atlas_gui    = atlas_mission_manager.atlas_gui:main',
        ],
    },
)
