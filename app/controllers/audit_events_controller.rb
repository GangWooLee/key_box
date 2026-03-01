class AuditEventsController < ApplicationController
  EVENTS_PER_PAGE = 50

  def index
    @vault = current_user.personal_vault
    @audit_events = @vault.audit_events
      .includes(:user, :secret)
      .recent
      .limit(EVENTS_PER_PAGE)
      .offset(page_offset)
    @page = current_page
  end

  private

  def current_page
    [ params[:page].to_i, 1 ].max
  end

  def page_offset
    (current_page - 1) * EVENTS_PER_PAGE
  end
end
