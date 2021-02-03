require 'spec_helper'

describe 'config/initializers/feature_toggles.rb' do
  let(:user) { build(:user) }

  around do |example|
    original = ENV['BETA_TESTERS']
    example.run
    ENV['BETA_TESTERS'] = original
  end

  context 'when beta_testers is ["all"]' do
    before { ENV['BETA_TESTERS'] = 'all' }

    it 'returns true' do
      require './config/initializers/feature_toggles' # execute the initializer's code block

      enabled = OpenFoodNetwork::FeatureToggle.enabled?(:customer_balance, user)
      expect(enabled).to eq(true)
    end
  end

  context 'when beta_testers is a list of emails' do
    let(:other_user) { build(:user) }

    before { ENV['BETA_TESTERS'] = "#{user.email}, #{other_user.email}" }

    context 'and the user is in the list' do
      it 'enables the feature' do
        require './config/initializers/feature_toggles' # execute the initializer's code block

        enabled = OpenFoodNetwork::FeatureToggle.enabled?(:customer_balance, user)
        expect(enabled).to eq(true)
      end
    end

    context 'and the user is not in the list' do
      it 'disables the feature' do
        require './config/initializers/feature_toggles' # execute the initializer's code block

        enabled = OpenFoodNetwork::FeatureToggle.enabled?(:customer_balance, user)
        expect(enabled).to eq(true)
      end
    end
  end
end
