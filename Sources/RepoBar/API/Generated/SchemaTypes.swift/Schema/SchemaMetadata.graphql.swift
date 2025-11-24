// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

protocol RepoBarGraphQL_SelectionSet: ApolloAPI.SelectionSet & ApolloAPI.RootSelectionSet
where Schema == RepoBarGraphQL.SchemaMetadata {}

protocol RepoBarGraphQL_InlineFragment: ApolloAPI.SelectionSet & ApolloAPI.InlineFragment
where Schema == RepoBarGraphQL.SchemaMetadata {}

protocol RepoBarGraphQL_MutableSelectionSet: ApolloAPI.MutableRootSelectionSet
where Schema == RepoBarGraphQL.SchemaMetadata {}

protocol RepoBarGraphQL_MutableInlineFragment: ApolloAPI.MutableSelectionSet & ApolloAPI.InlineFragment
where Schema == RepoBarGraphQL.SchemaMetadata {}

extension RepoBarGraphQL {
  typealias SelectionSet = RepoBarGraphQL_SelectionSet

  typealias InlineFragment = RepoBarGraphQL_InlineFragment

  typealias MutableSelectionSet = RepoBarGraphQL_MutableSelectionSet

  typealias MutableInlineFragment = RepoBarGraphQL_MutableInlineFragment

  enum SchemaMetadata: ApolloAPI.SchemaMetadata {
    nonisolated(unsafe) static let configuration: any ApolloAPI.SchemaConfiguration.Type = SchemaConfiguration.self

    static nonisolated func objectType(forTypename typename: String) -> ApolloAPI.Object? {
      switch typename {
      case "AddedToMergeQueueEvent": return RepoBarGraphQL.Objects.AddedToMergeQueueEvent
      case "AddedToProjectEvent": return RepoBarGraphQL.Objects.AddedToProjectEvent
      case "AddedToProjectV2Event": return RepoBarGraphQL.Objects.AddedToProjectV2Event
      case "App": return RepoBarGraphQL.Objects.App
      case "AssignedEvent": return RepoBarGraphQL.Objects.AssignedEvent
      case "AutoMergeDisabledEvent": return RepoBarGraphQL.Objects.AutoMergeDisabledEvent
      case "AutoMergeEnabledEvent": return RepoBarGraphQL.Objects.AutoMergeEnabledEvent
      case "AutoRebaseEnabledEvent": return RepoBarGraphQL.Objects.AutoRebaseEnabledEvent
      case "AutoSquashEnabledEvent": return RepoBarGraphQL.Objects.AutoSquashEnabledEvent
      case "AutomaticBaseChangeFailedEvent": return RepoBarGraphQL.Objects.AutomaticBaseChangeFailedEvent
      case "AutomaticBaseChangeSucceededEvent": return RepoBarGraphQL.Objects.AutomaticBaseChangeSucceededEvent
      case "BaseRefChangedEvent": return RepoBarGraphQL.Objects.BaseRefChangedEvent
      case "BaseRefDeletedEvent": return RepoBarGraphQL.Objects.BaseRefDeletedEvent
      case "BaseRefForcePushedEvent": return RepoBarGraphQL.Objects.BaseRefForcePushedEvent
      case "Blob": return RepoBarGraphQL.Objects.Blob
      case "BlockedByAddedEvent": return RepoBarGraphQL.Objects.BlockedByAddedEvent
      case "BlockedByRemovedEvent": return RepoBarGraphQL.Objects.BlockedByRemovedEvent
      case "BlockingAddedEvent": return RepoBarGraphQL.Objects.BlockingAddedEvent
      case "BlockingRemovedEvent": return RepoBarGraphQL.Objects.BlockingRemovedEvent
      case "Bot": return RepoBarGraphQL.Objects.Bot
      case "BranchProtectionRule": return RepoBarGraphQL.Objects.BranchProtectionRule
      case "BypassForcePushAllowance": return RepoBarGraphQL.Objects.BypassForcePushAllowance
      case "BypassPullRequestAllowance": return RepoBarGraphQL.Objects.BypassPullRequestAllowance
      case "CWE": return RepoBarGraphQL.Objects.CWE
      case "CheckRun": return RepoBarGraphQL.Objects.CheckRun
      case "CheckSuite": return RepoBarGraphQL.Objects.CheckSuite
      case "ClosedEvent": return RepoBarGraphQL.Objects.ClosedEvent
      case "CodeOfConduct": return RepoBarGraphQL.Objects.CodeOfConduct
      case "CommentDeletedEvent": return RepoBarGraphQL.Objects.CommentDeletedEvent
      case "Commit": return RepoBarGraphQL.Objects.Commit
      case "CommitComment": return RepoBarGraphQL.Objects.CommitComment
      case "CommitCommentThread": return RepoBarGraphQL.Objects.CommitCommentThread
      case "Comparison": return RepoBarGraphQL.Objects.Comparison
      case "ConnectedEvent": return RepoBarGraphQL.Objects.ConnectedEvent
      case "ConvertToDraftEvent": return RepoBarGraphQL.Objects.ConvertToDraftEvent
      case "ConvertedFromDraftEvent": return RepoBarGraphQL.Objects.ConvertedFromDraftEvent
      case "ConvertedNoteToIssueEvent": return RepoBarGraphQL.Objects.ConvertedNoteToIssueEvent
      case "ConvertedToDiscussionEvent": return RepoBarGraphQL.Objects.ConvertedToDiscussionEvent
      case "CrossReferencedEvent": return RepoBarGraphQL.Objects.CrossReferencedEvent
      case "DemilestonedEvent": return RepoBarGraphQL.Objects.DemilestonedEvent
      case "DependabotUpdate": return RepoBarGraphQL.Objects.DependabotUpdate
      case "DependencyGraphManifest": return RepoBarGraphQL.Objects.DependencyGraphManifest
      case "DeployKey": return RepoBarGraphQL.Objects.DeployKey
      case "DeployedEvent": return RepoBarGraphQL.Objects.DeployedEvent
      case "Deployment": return RepoBarGraphQL.Objects.Deployment
      case "DeploymentEnvironmentChangedEvent": return RepoBarGraphQL.Objects.DeploymentEnvironmentChangedEvent
      case "DeploymentReview": return RepoBarGraphQL.Objects.DeploymentReview
      case "DeploymentStatus": return RepoBarGraphQL.Objects.DeploymentStatus
      case "DisconnectedEvent": return RepoBarGraphQL.Objects.DisconnectedEvent
      case "Discussion": return RepoBarGraphQL.Objects.Discussion
      case "DiscussionCategory": return RepoBarGraphQL.Objects.DiscussionCategory
      case "DiscussionComment": return RepoBarGraphQL.Objects.DiscussionComment
      case "DiscussionPoll": return RepoBarGraphQL.Objects.DiscussionPoll
      case "DiscussionPollOption": return RepoBarGraphQL.Objects.DiscussionPollOption
      case "DraftIssue": return RepoBarGraphQL.Objects.DraftIssue
      case "Enterprise": return RepoBarGraphQL.Objects.Enterprise
      case "EnterpriseAdministratorInvitation": return RepoBarGraphQL.Objects.EnterpriseAdministratorInvitation
      case "EnterpriseIdentityProvider": return RepoBarGraphQL.Objects.EnterpriseIdentityProvider
      case "EnterpriseMemberInvitation": return RepoBarGraphQL.Objects.EnterpriseMemberInvitation
      case "EnterpriseRepositoryInfo": return RepoBarGraphQL.Objects.EnterpriseRepositoryInfo
      case "EnterpriseServerInstallation": return RepoBarGraphQL.Objects.EnterpriseServerInstallation
      case "EnterpriseServerUserAccount": return RepoBarGraphQL.Objects.EnterpriseServerUserAccount
      case "EnterpriseServerUserAccountEmail": return RepoBarGraphQL.Objects.EnterpriseServerUserAccountEmail
      case "EnterpriseServerUserAccountsUpload": return RepoBarGraphQL.Objects.EnterpriseServerUserAccountsUpload
      case "EnterpriseUserAccount": return RepoBarGraphQL.Objects.EnterpriseUserAccount
      case "Environment": return RepoBarGraphQL.Objects.Environment
      case "ExternalIdentity": return RepoBarGraphQL.Objects.ExternalIdentity
      case "Gist": return RepoBarGraphQL.Objects.Gist
      case "GistComment": return RepoBarGraphQL.Objects.GistComment
      case "HeadRefDeletedEvent": return RepoBarGraphQL.Objects.HeadRefDeletedEvent
      case "HeadRefForcePushedEvent": return RepoBarGraphQL.Objects.HeadRefForcePushedEvent
      case "HeadRefRestoredEvent": return RepoBarGraphQL.Objects.HeadRefRestoredEvent
      case "IpAllowListEntry": return RepoBarGraphQL.Objects.IpAllowListEntry
      case "Issue": return RepoBarGraphQL.Objects.Issue
      case "IssueComment": return RepoBarGraphQL.Objects.IssueComment
      case "IssueConnection": return RepoBarGraphQL.Objects.IssueConnection
      case "IssueType": return RepoBarGraphQL.Objects.IssueType
      case "IssueTypeAddedEvent": return RepoBarGraphQL.Objects.IssueTypeAddedEvent
      case "IssueTypeChangedEvent": return RepoBarGraphQL.Objects.IssueTypeChangedEvent
      case "IssueTypeRemovedEvent": return RepoBarGraphQL.Objects.IssueTypeRemovedEvent
      case "Label": return RepoBarGraphQL.Objects.Label
      case "LabeledEvent": return RepoBarGraphQL.Objects.LabeledEvent
      case "Language": return RepoBarGraphQL.Objects.Language
      case "License": return RepoBarGraphQL.Objects.License
      case "LinkedBranch": return RepoBarGraphQL.Objects.LinkedBranch
      case "LockedEvent": return RepoBarGraphQL.Objects.LockedEvent
      case "Mannequin": return RepoBarGraphQL.Objects.Mannequin
      case "MarkedAsDuplicateEvent": return RepoBarGraphQL.Objects.MarkedAsDuplicateEvent
      case "MarketplaceCategory": return RepoBarGraphQL.Objects.MarketplaceCategory
      case "MarketplaceListing": return RepoBarGraphQL.Objects.MarketplaceListing
      case "MemberFeatureRequestNotification": return RepoBarGraphQL.Objects.MemberFeatureRequestNotification
      case "MembersCanDeleteReposClearAuditEntry": return RepoBarGraphQL.Objects.MembersCanDeleteReposClearAuditEntry
      case "MembersCanDeleteReposDisableAuditEntry": return RepoBarGraphQL.Objects.MembersCanDeleteReposDisableAuditEntry
      case "MembersCanDeleteReposEnableAuditEntry": return RepoBarGraphQL.Objects.MembersCanDeleteReposEnableAuditEntry
      case "MentionedEvent": return RepoBarGraphQL.Objects.MentionedEvent
      case "MergeQueue": return RepoBarGraphQL.Objects.MergeQueue
      case "MergeQueueEntry": return RepoBarGraphQL.Objects.MergeQueueEntry
      case "MergedEvent": return RepoBarGraphQL.Objects.MergedEvent
      case "MigrationSource": return RepoBarGraphQL.Objects.MigrationSource
      case "Milestone": return RepoBarGraphQL.Objects.Milestone
      case "MilestonedEvent": return RepoBarGraphQL.Objects.MilestonedEvent
      case "MovedColumnsInProjectEvent": return RepoBarGraphQL.Objects.MovedColumnsInProjectEvent
      case "OIDCProvider": return RepoBarGraphQL.Objects.OIDCProvider
      case "OauthApplicationCreateAuditEntry": return RepoBarGraphQL.Objects.OauthApplicationCreateAuditEntry
      case "OrgAddBillingManagerAuditEntry": return RepoBarGraphQL.Objects.OrgAddBillingManagerAuditEntry
      case "OrgAddMemberAuditEntry": return RepoBarGraphQL.Objects.OrgAddMemberAuditEntry
      case "OrgBlockUserAuditEntry": return RepoBarGraphQL.Objects.OrgBlockUserAuditEntry
      case "OrgConfigDisableCollaboratorsOnlyAuditEntry": return RepoBarGraphQL.Objects.OrgConfigDisableCollaboratorsOnlyAuditEntry
      case "OrgConfigEnableCollaboratorsOnlyAuditEntry": return RepoBarGraphQL.Objects.OrgConfigEnableCollaboratorsOnlyAuditEntry
      case "OrgCreateAuditEntry": return RepoBarGraphQL.Objects.OrgCreateAuditEntry
      case "OrgDisableOauthAppRestrictionsAuditEntry": return RepoBarGraphQL.Objects.OrgDisableOauthAppRestrictionsAuditEntry
      case "OrgDisableSamlAuditEntry": return RepoBarGraphQL.Objects.OrgDisableSamlAuditEntry
      case "OrgDisableTwoFactorRequirementAuditEntry": return RepoBarGraphQL.Objects.OrgDisableTwoFactorRequirementAuditEntry
      case "OrgEnableOauthAppRestrictionsAuditEntry": return RepoBarGraphQL.Objects.OrgEnableOauthAppRestrictionsAuditEntry
      case "OrgEnableSamlAuditEntry": return RepoBarGraphQL.Objects.OrgEnableSamlAuditEntry
      case "OrgEnableTwoFactorRequirementAuditEntry": return RepoBarGraphQL.Objects.OrgEnableTwoFactorRequirementAuditEntry
      case "OrgInviteMemberAuditEntry": return RepoBarGraphQL.Objects.OrgInviteMemberAuditEntry
      case "OrgInviteToBusinessAuditEntry": return RepoBarGraphQL.Objects.OrgInviteToBusinessAuditEntry
      case "OrgOauthAppAccessApprovedAuditEntry": return RepoBarGraphQL.Objects.OrgOauthAppAccessApprovedAuditEntry
      case "OrgOauthAppAccessBlockedAuditEntry": return RepoBarGraphQL.Objects.OrgOauthAppAccessBlockedAuditEntry
      case "OrgOauthAppAccessDeniedAuditEntry": return RepoBarGraphQL.Objects.OrgOauthAppAccessDeniedAuditEntry
      case "OrgOauthAppAccessRequestedAuditEntry": return RepoBarGraphQL.Objects.OrgOauthAppAccessRequestedAuditEntry
      case "OrgOauthAppAccessUnblockedAuditEntry": return RepoBarGraphQL.Objects.OrgOauthAppAccessUnblockedAuditEntry
      case "OrgRemoveBillingManagerAuditEntry": return RepoBarGraphQL.Objects.OrgRemoveBillingManagerAuditEntry
      case "OrgRemoveMemberAuditEntry": return RepoBarGraphQL.Objects.OrgRemoveMemberAuditEntry
      case "OrgRemoveOutsideCollaboratorAuditEntry": return RepoBarGraphQL.Objects.OrgRemoveOutsideCollaboratorAuditEntry
      case "OrgRestoreMemberAuditEntry": return RepoBarGraphQL.Objects.OrgRestoreMemberAuditEntry
      case "OrgRestoreMemberMembershipOrganizationAuditEntryData": return RepoBarGraphQL.Objects.OrgRestoreMemberMembershipOrganizationAuditEntryData
      case "OrgRestoreMemberMembershipRepositoryAuditEntryData": return RepoBarGraphQL.Objects.OrgRestoreMemberMembershipRepositoryAuditEntryData
      case "OrgRestoreMemberMembershipTeamAuditEntryData": return RepoBarGraphQL.Objects.OrgRestoreMemberMembershipTeamAuditEntryData
      case "OrgUnblockUserAuditEntry": return RepoBarGraphQL.Objects.OrgUnblockUserAuditEntry
      case "OrgUpdateDefaultRepositoryPermissionAuditEntry": return RepoBarGraphQL.Objects.OrgUpdateDefaultRepositoryPermissionAuditEntry
      case "OrgUpdateMemberAuditEntry": return RepoBarGraphQL.Objects.OrgUpdateMemberAuditEntry
      case "OrgUpdateMemberRepositoryCreationPermissionAuditEntry": return RepoBarGraphQL.Objects.OrgUpdateMemberRepositoryCreationPermissionAuditEntry
      case "OrgUpdateMemberRepositoryInvitationPermissionAuditEntry": return RepoBarGraphQL.Objects.OrgUpdateMemberRepositoryInvitationPermissionAuditEntry
      case "Organization": return RepoBarGraphQL.Objects.Organization
      case "OrganizationIdentityProvider": return RepoBarGraphQL.Objects.OrganizationIdentityProvider
      case "OrganizationInvitation": return RepoBarGraphQL.Objects.OrganizationInvitation
      case "OrganizationMigration": return RepoBarGraphQL.Objects.OrganizationMigration
      case "Package": return RepoBarGraphQL.Objects.Package
      case "PackageFile": return RepoBarGraphQL.Objects.PackageFile
      case "PackageTag": return RepoBarGraphQL.Objects.PackageTag
      case "PackageVersion": return RepoBarGraphQL.Objects.PackageVersion
      case "ParentIssueAddedEvent": return RepoBarGraphQL.Objects.ParentIssueAddedEvent
      case "ParentIssueRemovedEvent": return RepoBarGraphQL.Objects.ParentIssueRemovedEvent
      case "PinnedDiscussion": return RepoBarGraphQL.Objects.PinnedDiscussion
      case "PinnedEnvironment": return RepoBarGraphQL.Objects.PinnedEnvironment
      case "PinnedEvent": return RepoBarGraphQL.Objects.PinnedEvent
      case "PinnedIssue": return RepoBarGraphQL.Objects.PinnedIssue
      case "PrivateRepositoryForkingDisableAuditEntry": return RepoBarGraphQL.Objects.PrivateRepositoryForkingDisableAuditEntry
      case "PrivateRepositoryForkingEnableAuditEntry": return RepoBarGraphQL.Objects.PrivateRepositoryForkingEnableAuditEntry
      case "Project": return RepoBarGraphQL.Objects.Project
      case "ProjectCard": return RepoBarGraphQL.Objects.ProjectCard
      case "ProjectColumn": return RepoBarGraphQL.Objects.ProjectColumn
      case "ProjectV2": return RepoBarGraphQL.Objects.ProjectV2
      case "ProjectV2Field": return RepoBarGraphQL.Objects.ProjectV2Field
      case "ProjectV2Item": return RepoBarGraphQL.Objects.ProjectV2Item
      case "ProjectV2ItemFieldDateValue": return RepoBarGraphQL.Objects.ProjectV2ItemFieldDateValue
      case "ProjectV2ItemFieldIterationValue": return RepoBarGraphQL.Objects.ProjectV2ItemFieldIterationValue
      case "ProjectV2ItemFieldNumberValue": return RepoBarGraphQL.Objects.ProjectV2ItemFieldNumberValue
      case "ProjectV2ItemFieldSingleSelectValue": return RepoBarGraphQL.Objects.ProjectV2ItemFieldSingleSelectValue
      case "ProjectV2ItemFieldTextValue": return RepoBarGraphQL.Objects.ProjectV2ItemFieldTextValue
      case "ProjectV2ItemStatusChangedEvent": return RepoBarGraphQL.Objects.ProjectV2ItemStatusChangedEvent
      case "ProjectV2IterationField": return RepoBarGraphQL.Objects.ProjectV2IterationField
      case "ProjectV2SingleSelectField": return RepoBarGraphQL.Objects.ProjectV2SingleSelectField
      case "ProjectV2StatusUpdate": return RepoBarGraphQL.Objects.ProjectV2StatusUpdate
      case "ProjectV2View": return RepoBarGraphQL.Objects.ProjectV2View
      case "ProjectV2Workflow": return RepoBarGraphQL.Objects.ProjectV2Workflow
      case "PublicKey": return RepoBarGraphQL.Objects.PublicKey
      case "PullRequest": return RepoBarGraphQL.Objects.PullRequest
      case "PullRequestCommit": return RepoBarGraphQL.Objects.PullRequestCommit
      case "PullRequestCommitCommentThread": return RepoBarGraphQL.Objects.PullRequestCommitCommentThread
      case "PullRequestConnection": return RepoBarGraphQL.Objects.PullRequestConnection
      case "PullRequestReview": return RepoBarGraphQL.Objects.PullRequestReview
      case "PullRequestReviewComment": return RepoBarGraphQL.Objects.PullRequestReviewComment
      case "PullRequestReviewThread": return RepoBarGraphQL.Objects.PullRequestReviewThread
      case "PullRequestThread": return RepoBarGraphQL.Objects.PullRequestThread
      case "Push": return RepoBarGraphQL.Objects.Push
      case "PushAllowance": return RepoBarGraphQL.Objects.PushAllowance
      case "Query": return RepoBarGraphQL.Objects.Query
      case "Reaction": return RepoBarGraphQL.Objects.Reaction
      case "ReadyForReviewEvent": return RepoBarGraphQL.Objects.ReadyForReviewEvent
      case "Ref": return RepoBarGraphQL.Objects.Ref
      case "ReferencedEvent": return RepoBarGraphQL.Objects.ReferencedEvent
      case "Release": return RepoBarGraphQL.Objects.Release
      case "ReleaseAsset": return RepoBarGraphQL.Objects.ReleaseAsset
      case "ReleaseConnection": return RepoBarGraphQL.Objects.ReleaseConnection
      case "RemovedFromMergeQueueEvent": return RepoBarGraphQL.Objects.RemovedFromMergeQueueEvent
      case "RemovedFromProjectEvent": return RepoBarGraphQL.Objects.RemovedFromProjectEvent
      case "RemovedFromProjectV2Event": return RepoBarGraphQL.Objects.RemovedFromProjectV2Event
      case "RenamedTitleEvent": return RepoBarGraphQL.Objects.RenamedTitleEvent
      case "ReopenedEvent": return RepoBarGraphQL.Objects.ReopenedEvent
      case "RepoAccessAuditEntry": return RepoBarGraphQL.Objects.RepoAccessAuditEntry
      case "RepoAddMemberAuditEntry": return RepoBarGraphQL.Objects.RepoAddMemberAuditEntry
      case "RepoAddTopicAuditEntry": return RepoBarGraphQL.Objects.RepoAddTopicAuditEntry
      case "RepoArchivedAuditEntry": return RepoBarGraphQL.Objects.RepoArchivedAuditEntry
      case "RepoChangeMergeSettingAuditEntry": return RepoBarGraphQL.Objects.RepoChangeMergeSettingAuditEntry
      case "RepoConfigDisableAnonymousGitAccessAuditEntry": return RepoBarGraphQL.Objects.RepoConfigDisableAnonymousGitAccessAuditEntry
      case "RepoConfigDisableCollaboratorsOnlyAuditEntry": return RepoBarGraphQL.Objects.RepoConfigDisableCollaboratorsOnlyAuditEntry
      case "RepoConfigDisableContributorsOnlyAuditEntry": return RepoBarGraphQL.Objects.RepoConfigDisableContributorsOnlyAuditEntry
      case "RepoConfigDisableSockpuppetDisallowedAuditEntry": return RepoBarGraphQL.Objects.RepoConfigDisableSockpuppetDisallowedAuditEntry
      case "RepoConfigEnableAnonymousGitAccessAuditEntry": return RepoBarGraphQL.Objects.RepoConfigEnableAnonymousGitAccessAuditEntry
      case "RepoConfigEnableCollaboratorsOnlyAuditEntry": return RepoBarGraphQL.Objects.RepoConfigEnableCollaboratorsOnlyAuditEntry
      case "RepoConfigEnableContributorsOnlyAuditEntry": return RepoBarGraphQL.Objects.RepoConfigEnableContributorsOnlyAuditEntry
      case "RepoConfigEnableSockpuppetDisallowedAuditEntry": return RepoBarGraphQL.Objects.RepoConfigEnableSockpuppetDisallowedAuditEntry
      case "RepoConfigLockAnonymousGitAccessAuditEntry": return RepoBarGraphQL.Objects.RepoConfigLockAnonymousGitAccessAuditEntry
      case "RepoConfigUnlockAnonymousGitAccessAuditEntry": return RepoBarGraphQL.Objects.RepoConfigUnlockAnonymousGitAccessAuditEntry
      case "RepoCreateAuditEntry": return RepoBarGraphQL.Objects.RepoCreateAuditEntry
      case "RepoDestroyAuditEntry": return RepoBarGraphQL.Objects.RepoDestroyAuditEntry
      case "RepoRemoveMemberAuditEntry": return RepoBarGraphQL.Objects.RepoRemoveMemberAuditEntry
      case "RepoRemoveTopicAuditEntry": return RepoBarGraphQL.Objects.RepoRemoveTopicAuditEntry
      case "Repository": return RepoBarGraphQL.Objects.Repository
      case "RepositoryInvitation": return RepoBarGraphQL.Objects.RepositoryInvitation
      case "RepositoryMigration": return RepoBarGraphQL.Objects.RepositoryMigration
      case "RepositoryRule": return RepoBarGraphQL.Objects.RepositoryRule
      case "RepositoryRuleset": return RepoBarGraphQL.Objects.RepositoryRuleset
      case "RepositoryRulesetBypassActor": return RepoBarGraphQL.Objects.RepositoryRulesetBypassActor
      case "RepositoryTopic": return RepoBarGraphQL.Objects.RepositoryTopic
      case "RepositoryVisibilityChangeDisableAuditEntry": return RepoBarGraphQL.Objects.RepositoryVisibilityChangeDisableAuditEntry
      case "RepositoryVisibilityChangeEnableAuditEntry": return RepoBarGraphQL.Objects.RepositoryVisibilityChangeEnableAuditEntry
      case "RepositoryVulnerabilityAlert": return RepoBarGraphQL.Objects.RepositoryVulnerabilityAlert
      case "ReviewDismissalAllowance": return RepoBarGraphQL.Objects.ReviewDismissalAllowance
      case "ReviewDismissedEvent": return RepoBarGraphQL.Objects.ReviewDismissedEvent
      case "ReviewRequest": return RepoBarGraphQL.Objects.ReviewRequest
      case "ReviewRequestRemovedEvent": return RepoBarGraphQL.Objects.ReviewRequestRemovedEvent
      case "ReviewRequestedEvent": return RepoBarGraphQL.Objects.ReviewRequestedEvent
      case "SavedReply": return RepoBarGraphQL.Objects.SavedReply
      case "SecurityAdvisory": return RepoBarGraphQL.Objects.SecurityAdvisory
      case "SponsorsActivity": return RepoBarGraphQL.Objects.SponsorsActivity
      case "SponsorsListing": return RepoBarGraphQL.Objects.SponsorsListing
      case "SponsorsListingFeaturedItem": return RepoBarGraphQL.Objects.SponsorsListingFeaturedItem
      case "SponsorsTier": return RepoBarGraphQL.Objects.SponsorsTier
      case "Sponsorship": return RepoBarGraphQL.Objects.Sponsorship
      case "SponsorshipNewsletter": return RepoBarGraphQL.Objects.SponsorshipNewsletter
      case "Status": return RepoBarGraphQL.Objects.Status
      case "StatusCheckRollup": return RepoBarGraphQL.Objects.StatusCheckRollup
      case "StatusContext": return RepoBarGraphQL.Objects.StatusContext
      case "SubIssueAddedEvent": return RepoBarGraphQL.Objects.SubIssueAddedEvent
      case "SubIssueRemovedEvent": return RepoBarGraphQL.Objects.SubIssueRemovedEvent
      case "SubscribedEvent": return RepoBarGraphQL.Objects.SubscribedEvent
      case "Tag": return RepoBarGraphQL.Objects.Tag
      case "Team": return RepoBarGraphQL.Objects.Team
      case "TeamAddMemberAuditEntry": return RepoBarGraphQL.Objects.TeamAddMemberAuditEntry
      case "TeamAddRepositoryAuditEntry": return RepoBarGraphQL.Objects.TeamAddRepositoryAuditEntry
      case "TeamChangeParentTeamAuditEntry": return RepoBarGraphQL.Objects.TeamChangeParentTeamAuditEntry
      case "TeamDiscussion": return RepoBarGraphQL.Objects.TeamDiscussion
      case "TeamDiscussionComment": return RepoBarGraphQL.Objects.TeamDiscussionComment
      case "TeamRemoveMemberAuditEntry": return RepoBarGraphQL.Objects.TeamRemoveMemberAuditEntry
      case "TeamRemoveRepositoryAuditEntry": return RepoBarGraphQL.Objects.TeamRemoveRepositoryAuditEntry
      case "Topic": return RepoBarGraphQL.Objects.Topic
      case "TransferredEvent": return RepoBarGraphQL.Objects.TransferredEvent
      case "Tree": return RepoBarGraphQL.Objects.Tree
      case "UnassignedEvent": return RepoBarGraphQL.Objects.UnassignedEvent
      case "UnlabeledEvent": return RepoBarGraphQL.Objects.UnlabeledEvent
      case "UnlockedEvent": return RepoBarGraphQL.Objects.UnlockedEvent
      case "UnmarkedAsDuplicateEvent": return RepoBarGraphQL.Objects.UnmarkedAsDuplicateEvent
      case "UnpinnedEvent": return RepoBarGraphQL.Objects.UnpinnedEvent
      case "UnsubscribedEvent": return RepoBarGraphQL.Objects.UnsubscribedEvent
      case "User": return RepoBarGraphQL.Objects.User
      case "UserBlockedEvent": return RepoBarGraphQL.Objects.UserBlockedEvent
      case "UserContentEdit": return RepoBarGraphQL.Objects.UserContentEdit
      case "UserList": return RepoBarGraphQL.Objects.UserList
      case "UserNamespaceRepository": return RepoBarGraphQL.Objects.UserNamespaceRepository
      case "UserStatus": return RepoBarGraphQL.Objects.UserStatus
      case "VerifiableDomain": return RepoBarGraphQL.Objects.VerifiableDomain
      case "Workflow": return RepoBarGraphQL.Objects.Workflow
      case "WorkflowRun": return RepoBarGraphQL.Objects.WorkflowRun
      case "WorkflowRunFile": return RepoBarGraphQL.Objects.WorkflowRunFile
      default: return nil
      }
    }
  }

  enum Objects {}
  enum Interfaces {}
  enum Unions {}

}
