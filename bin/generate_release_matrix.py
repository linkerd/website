#!/usr/bin/env python3
# Author: Corey Osman <corey@logicminds.biz>
# Purpose: Geneate a list in specified format of all the linkerd charts by app version
# Usage: ./generate_release_matrix.py [--format=json|table|yaml] [--update_repo]
# Notes: Help determine which charts go with which app versions
# Notes: This is primary aimed at the stable release only, although a slight modification 
#        could yeild support for edge and Enterprise releases too.  Right now edge versions
#        follow date schemes and the manual mappings do not work


import subprocess
import json
import yaml
import argparse


charts = [
   # "linkerd2",  # This makes the search return results for everything
    "linkerd2-cni",
    "linkerd-viz",
    "linkerd-control-plane",
    "linkerd-jaeger",
    "linkerd-multicluster",
    "linkerd-failover",
]

# these versions are old and do not have the proper mappings anyways
ignored_y_versions = [6, 7, 8, 9]

# Manually map in the old chart, otherwise we get duplicates mixed in
linkerd2_map = {
    '2.11': {
        "linkerd2": {
            "chart_name": "linkerd2",
            "chart_version": "2.11.5",
            "chart_url": "https://artifacthub.io/packages/helm/linkerd2/linkerd2/2.11.5"
        }
    },
    '2.10': {
        "linkerd2": {
            "chart_name": "linkerd2",
            "chart_version": "2.10.2",
            "chart_url": "https://artifacthub.io/packages/helm/linkerd2/linkerd2/2.10.2"
        }
    }
}
# Manually map in the crds because there is no app version associated with them
crds_map = {
    "2.12": {
        "linkerd-crds": {
            "chart_name": "linkerd-crds",
            "chart_version": "1.6.1",
            "chart_url": "https://artifacthub.io/packages/helm/linkerd2/linkerd-crds/1.6.1"
        }
    },
    "2.13": {
        "linkerd-crds": {
            "chart_name": "linkerd-crds",
            "chart_version": "1.6.1",
            "chart_url": "https://artifacthub.io/packages/helm/linkerd2/linkerd-crds/1.6.1"
        }
    },
    "2.14": {
        "linkerd-crds": {
            "chart_name": "linkerd-crds",
            "chart_version": "1.8.0",
            "chart_url": "https://artifacthub.io/packages/helm/linkerd2/linkerd-crds/1.8.0"
        }
    },
}


def find_newest_versions(versions):
    """
    Finds the newest version with the highest X value for a given Y version

    Parameters:
        versions (list): A list of version objects
        Example: [('linkerd2/linkerd2', '2.11.5', 'stable-2.11.5'), ('linkerd2/linkerd2', '2.11.4', 'stable-2.11.4')

    Returns:
        list: A list of version objects
        Example: [('linkerd2/linkerd2', '2.11.5', 'stable-2.11.5'),
          ('linkerd2/linkerd2', '2.10.2', 'stable-2.10.2'),
          ('linkerd2/linkerd2', '30.12.1', 'stable-2.14.3'),
          ('linkerd2/linkerd2', '30.8.5', 'stable-2.13.7'),
          ('linkerd2/linkerd2', '30.3.8', 'stable-2.12.6'),
          ('linkerd2/linkerd2', '2.11.5', 'stable-2.11.5'),
          ('linkerd2/linkerd2', '2.10.2', 'stable-2.10.2')]

    """
    winners = {}
    for entry in versions:
        _, _, version, _ = entry
        try:
            x, y, z = map(int, version.split("-")[1].split("."))
            if not y in ignored_y_versions:
                current_winner = winners.get(
                    f"{x}.{y}.Z", {"x": x, "y": y, "z": z, version: version}
                )
                if current_winner["y"] == y and z >= current_winner["z"]:
                    # new winner
                    winners[f"{x}.{y}.Z"] = {"x": x, "y": y, "z": z, "version": version}

        except IndexError:
            next
        except UnboundLocalError:
            next

    latest_versions = [v["version"] for v in winners.values()]
    common_versions = []

    for version in versions:
        if version[2] in latest_versions:
            common_versions.append(version)

    return common_versions


def combine_charts_by_app_version(versions):
    """
    Gathers all charts tuples under a single app version

    Parameters:
        versions (list): Raw list of versions tuples
        [('linkerd2/linkerd-control-plane', '1.12.7', 'stable-2.13.7'),
          ('linkerd2/linkerd-control-plane', '1.16.4', 'stable-2.14.3'),
            ('linkerd2/linkerd-control-plane', '1.9.8', 'stable-2.12.6')]

    Returns:
        dict: versions object after combing under an app version.
        {'stable-2.13.7': 
          {'linkerd2-crds': 
            {'chart_name': 'linkerd2/linkerd2-crds', 'chart_version': '1.6.1'}, 
            'linkerd-jaeger': {
                'chart_name': 'linkerd2/linkerd-jaeger', 'chart_version': '30.8.7'}
            }
        }

    """
    combined_charts = {}
    for chart, version, app_version, link in versions:
        name = chart # chart.split("/")[1]
       
        if not app_version:
            app_version = version
        if not combined_charts.get(app_version):
            combined_charts[app_version] = {}

        combined_charts[app_version][name] = {
            "chart_name": chart,
            "chart_version": version,
            "chart_url": link
        }
        # merge in the crds chart info if it exist for the version
        x, y, z = map(int, app_version.split("-")[1].split("."))
        try:
            if y > 11 and x == 2:
                combined_charts[app_version] = {**combined_charts[app_version], **crds_map[f"{x}.{y}"]}
            elif x == 2:
                combined_charts[app_version] = {**combined_charts[app_version], **linkerd2_map[f"{x}.{y}"]}
        except KeyError as e:
            print(e)
    
    # sorted(combined_charts.items(), key=lambda x: x[0] != "stable-2.11.5")
    return combined_charts

def find_repo_name(release_type):
    if release_type == "stable":
        repo_name = "linkerd2"
    elif release_type == "edge":
        repo_name = "linkerd2-edge"
    else:
        repo_name = "linkerd2"
    
    return repo_name

def add_repo(release_type, helm_url, repo_name):
    command = ["helm", "repo", "add", repo_name, f"{helm_url}/{release_type}"]

    try:
        process = subprocess.Popen(
            command, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True
        )
        stdout, stderr = process.communicate()

    except OSError as e:
        print(f"Error: {e}")
    
    return repo_name


def update_repo(release_type, helm_url, repo_name):
    add_repo(release_type, helm_url, repo_name)

    command = ["helm", "repo", "update", repo_name]

    try:
        process = subprocess.Popen(
            command, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True
        )
        stdout, stderr = process.communicate()

    except OSError as e:
        print(f"Error: {e}")

    return repo_name

def list_chart_versions(charts, repo_name, latest_only=True):
    """
    Fetches all the linkerd charts 

    Parameters:
    charts (list): A list of chart names to fetch

    Returns:
        dict: A list of chart version tuples
        Example: {('linkerd2/linkerd2', '2.11.5', 'stable-2.11.5')}
      
    """
    all_versions = set()
   

    for chart in charts:
        # helm repo update linkerd2
        search_term = f"{repo_name}/{chart}"
        command = ["helm", "search", "repo", search_term, "--versions", "--output", "json"]
        try:
            process = subprocess.Popen(
                command, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True
            )
            stdout, stderr = process.communicate()
            
            if process.returncode == 0:
                chart_data = json.loads(stdout)
                versions = [
                    (chart, item["version"], item["app_version"], f"https://artifacthub.io/packages/helm/{repo_name}/{chart}/{item['version']}") for item in chart_data
                ]
                if latest_only:
                    latest_versions = find_newest_versions(versions)
                else:
                    latest_versions = versions

                all_versions.update(latest_versions)
            else:
                print(f"Error: Failed to list chart versions for {chart}")
                print(stderr)
        except OSError as e:
            print(f"Error: {e}")
    
    return sorted(all_versions)


def print_output(data, format):
    if format == "json":
        print(json.dumps(data, indent=4))
    elif format == "yaml":
        print(yaml.dump(data, indent=4))
    else:
        try:
            from tabulate import tabulate
        except ImportError as e:
            print("Please install tabulate: pip3 install tabulate")
            exit(1)
        headers = ["App Version", "Chart Name", "Chart Version"]
        table = []
        for app_version, charts in sorted(
            data.items(), reverse=True
        ):
            for chart_name, chart_data in charts.items():
                table.append(
                    [app_version, chart_data["chart_name"], chart_data["chart_version"]]
                )
            print(tabulate(table, headers=headers, tablefmt="github"))
            print("\n")
            table = []


parser = argparse.ArgumentParser(description="List linkerd chart versions in various formats")
parser.add_argument(
    "--format", default="table", choices=["table", "json", "yaml"], help="Desired Output format, defaults to table"
)
parser.add_argument('--release_type', choices=["stable", "edge"], default="stable", help="Use the specific release type, defaults to stable")
parser.add_argument('--helm_url', choices=["https://helm.linkerd.io"], default="https://helm.linkerd.io", help="The helm url to use" )
args = parser.parse_args()

repo_name = find_repo_name(args.release_type)
update_repo(args.release_type, args.helm_url, repo_name)

all_versions = list_chart_versions(charts, repo_name)
combined_charts_by_app_version = combine_charts_by_app_version(all_versions)
print_output(combined_charts_by_app_version, args.format)