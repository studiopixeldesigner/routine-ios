"""Fabrique le raccourci « Pas pour Ma routine » (non signé) : lit le total de pas du jour
dans Santé et l'envoie à l'appli par le lien maroutine://pas?n=…"""
import plistlib, sys, uuid

u_stats = str(uuid.uuid4()).upper()
u_samples = str(uuid.uuid4()).upper()
u_url = str(uuid.uuid4()).upper()

def sortie(uid, nom):
    return {"Value": {"Type": "ActionOutput", "OutputUUID": uid, "OutputName": nom},
            "WFSerializationType": "WFTextTokenAttachment"}

lien = "maroutine://pas?n=￼"
actions = [
    {   # Rechercher des échantillons de santé : nombre de pas, aujourd'hui
        "WFWorkflowActionIdentifier": "is.workflow.actions.filter.health.quantity",
        "WFWorkflowActionParameters": {
            "UUID": u_samples,
            "WFContentItemFilter": {
                "Value": {
                    "WFActionParameterFilterPrefix": 1,
                    "WFContentPredicateBoundedDate": False,
                    "WFActionParameterFilterTemplates": [
                        {"Bounded": True, "Operator": 4, "Property": "Type", "Removable": False,
                         "Values": {"Enumeration": {"Value": "Steps", "WFSerializationType": "WFStringSubstitutableState"}}},
                        {"Operator": 1002, "Property": "Start Date", "Removable": True,
                         "Values": {"Unit": 16}},
                    ],
                },
                "WFSerializationType": "WFContentPredicateTableTemplate",
            },
            "WFContentItemSortProperty": "Start Date",
            "WFContentItemSortOrder": "Latest First",
        },
    },
    {   # Calculer les statistiques : somme
        "WFWorkflowActionIdentifier": "is.workflow.actions.statistics",
        "WFWorkflowActionParameters": {
            "UUID": u_stats,
            "WFStatisticsOperation": "Sum",
            "Input": sortie(u_samples, "Health Samples"),
        },
    },
    {   # Lien vers l'appli
        "WFWorkflowActionIdentifier": "is.workflow.actions.url",
        "WFWorkflowActionParameters": {
            "UUID": u_url,
            "WFURLActionURL": {
                "Value": {"string": lien,
                          "attachmentsByRange": {"{%d, 1}" % lien.index("￼"):
                                                 {"Type": "ActionOutput", "OutputUUID": u_stats, "OutputName": "Statistics"}}},
                "WFSerializationType": "WFTextTokenString",
            },
        },
    },
    {   # Ouvrir le lien
        "WFWorkflowActionIdentifier": "is.workflow.actions.openurl",
        "WFWorkflowActionParameters": {"WFInput": sortie(u_url, "URL")},
    },
]

raccourci = {
    "WFWorkflowClientVersion": "2607.0.2",
    "WFWorkflowMinimumClientVersion": 900,
    "WFWorkflowMinimumClientVersionString": "900",
    "WFWorkflowIcon": {"WFWorkflowIconStartColor": 4282601983, "WFWorkflowIconGlyphNumber": 59511},
    "WFWorkflowImportQuestions": [],
    "WFWorkflowInputContentItemClasses": [],
    "WFWorkflowOutputContentItemClasses": [],
    "WFWorkflowTypes": [],
    "WFWorkflowHasShortcutInputVariables": False,
    "WFQuickActionSurfaces": [],
    "WFWorkflowActions": actions,
}
with open(sys.argv[1], "wb") as f:
    plistlib.dump(raccourci, f, fmt=plistlib.FMT_BINARY)
print("écrit", sys.argv[1])
