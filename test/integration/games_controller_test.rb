require "test_helper"

describe "GamesController Integration Test" do

  before do
    @service = login_service
    @tournament = create(:started_tournament)
    @rating_period = @tournament.current_rating_period
    @user2 = create(:user)
    @rating1 = create(:rating, :rating_period => @rating_period, :user => @service.user)
    @rating2 = create(:rating, :rating_period => @rating_period, :user => @user2)
  end

  describe "creation" do
    it "must be created" do
      visit tournament_path @tournament
      click_link I18n.t('tournaments.show.log_a_game')
      click_button I18n.t('helpers.submit.create')
      must_have_content @rating1.user.name
      must_have_content @rating2.user.name
      must_have_content I18n.t('games.game_rank.unconfirmed')
    end

    it "must send confirmation email" do
      visit tournament_path @tournament
      click_link I18n.t('tournaments.show.log_a_game')
      click_button I18n.t('helpers.submit.create')
      ActionMailer::Base.deliveries.length.must_equal 1
      email = ActionMailer::Base.deliveries.first
      email.to.must_equal [@user2.email]
    end
  end

  describe "confirming" do
    before do
      @game = create(:game, :tournament => @tournament)
      @game_rank1 = create(:game_rank, :game => @game, :user => @rating1.user, :position => 1)
      @game_rank2 = create(:game_rank, :game => @game, :user => @rating2.user, :position => 2)
    end

    it "must be confirmed" do
      visit game_path @game
      click_button I18n.t('games.show.confirm')
      must_have_content I18n.t('games.game_rank.confirmed', :time => 'less than a minute')
    end

    describe "on final confirmation" do
      it "must update game on final confirmation" do
        @game_rank2.confirm
        visit game_path @game
        click_button I18n.t('games.show.confirm')
        @game.reload.confirmed?.must_equal true
      end

      it "must send game confirmed email to other users" do
        @game_rank2.confirm
        visit game_path @game
        click_button I18n.t('games.show.confirm')
        ActionMailer::Base.deliveries.length.must_equal 1
        email = ActionMailer::Base.deliveries.first
        email.to.must_equal [@user2.email]
      end
    end
  end

end
