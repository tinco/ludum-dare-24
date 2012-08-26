WebsocketRails::EventMap.describe do
  # You can use this file to map incoming events to controller actions.
  # One event can be mapped to any number of controller actions. The
  # actions will be executed in the order they were subscribed.
	
  subscribe :client_connected, :to => GameController, :with_method => :new_player
  subscribe :client_disconnected, :to => GameController, :with_method => :player_disconnected

  subscribe :act, :to => GameController, :with_method => :act
end
