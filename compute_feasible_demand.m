function D_feas = compute_feasible_demand(D_base, q_offer_t, ell)
% Updated feasible demand clamp with headroom removed, i.e line limit.
% q_offer_t is N x T and already reflects the current follower offers.

% Loss-adjusted offered supply is the only system-wide clamp left here.
deliverable = (1 - ell(:))' * q_offer_t;

% The leader only tries to serve what is both demanded and currently deliverable.
D_feas = min(D_base(:), deliverable(:));

end
