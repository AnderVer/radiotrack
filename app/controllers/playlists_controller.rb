# frozen_string_literal: true

class PlaylistsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_playlist, only: [:show, :edit, :update, :destroy]

  # GET /playlists
  def index
    @playlists = current_user.playlists.includes(:playlist_items).order(created_at: :desc)
  end

  # GET /playlists/new
  def new
    @playlist = current_user.playlists.build
  end

  # GET /playlists/:id
  def show
    @playlist_items = @playlist.playlist_items.order(:position)
  end

  # POST /playlists
  def create
    # Check limit
    limit = current_user.playlists_limit
    if limit && current_user.playlists.count >= limit
      redirect_to playlists_path, alert: "Достигнут лимит плейлистов (#{limit})"
      return
    end

    @playlist = current_user.playlists.build(playlist_params)

    if @playlist.save
      redirect_to playlists_path, notice: "Плейлист создан"
    else
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /playlists/:id
  def update
    if @playlist.update(playlist_params)
      redirect_to playlists_path, notice: "Плейлист обновлён"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /playlists/:id
  def destroy
    @playlist.destroy
    redirect_to playlists_path, notice: "Плейлист удалён"
  end

  private

  def set_playlist
    @playlist = current_user.playlists.find_by(id: params[:id])
    unless @playlist
      redirect_to playlists_path, alert: "Плейлист не найден"
    end
  end

  def playlist_params
    params.require(:playlist).permit(:title, :local_id)
  end
end
